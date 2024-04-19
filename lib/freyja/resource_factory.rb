# frozen_string_literal: true

module Freyja
  # Provides access to generic methods for converting to/from
  # {Valkyrie::Resource} and {Valkyrie::Persistence::Postgres::ORM::Resource}.
  class ResourceFactory < Valkyrie::Persistence::Postgres::ResourceFactory
    # @param object [Valkyrie::Persistence::Postgres::ORM::Resource] AR
    #   record to be converted.
    # @return [Valkyrie::Resource] Model representation of the AR record.
    def to_resource(object:)
      MigrateFilesFromFedoraJob.conditionally_perform_later(object:, resource_factory: self)
      super
    end

    ##
    # Responsible for conditionally enqueuing the file and thumbnail migration
    # logic of an ActiveFedora object.
    class MigrateFilesFromFedoraJob < Hyrax::ApplicationJob
      def self.already_migrated?(resource:)
        # NOTE: Because we're writing this code in a Freyja adapter, we're
        # assuming that we're using a Goddess strategy for lazy migration.
        query_service_for_migrating_to = Hyrax.query_service.services.first

        # TODO: Consider writing a custom query as this is slow compared to a
        # simple `SELECT COUNT(id) WHERE ids IN (?)'
        query_service_for_migrating_to.find_many_by_ids(ids: resource.file_ids).any?
      end
      ##
      # Check the conditions of the given object to see if it should be
      # enqueued.  Given how frequently the logic could fire, we don't want to
      # enqueue a load of jobs that all bail immediately.
      #
      # @param object [Valkyrie::Persistence::Postgres::ORM::Resource] AR
      #        record to be converted.
      def self.conditionally_perform_later(object:, resource_factory:)
        # TODO How might we consider handling a failed convert?  I believe we
        # should raise a loud exception as this is almost certainly a
        # configuration error.
        resource = ::Valkyrie::Persistence::Postgres::ORMConverter.new(object, resource_factory:).convert!

        # Only migrate files for file sets objects
        return :not_a_fileset unless resource.respond_to?(:file_ids)

        # Looking for low hanging fruit (e.g. not overly costly to perform) to
        # avoid flooding the job queue.
        #
        # TODO: Is there a better logic for this?  Maybe check if one or more of
        # the file_ids is in the storage adapter?
        return :already_migrated if already_migrated?(resource:)

        # NOTE: Should we pass the objec tand re-convert it?  We'll see how this all
        # works.
        perform_later(object)
      end

      ##
      # Favor {.conditionally_perform_later} as it performs guards on the
      # resource submission.
      #
      # @param resource [Object]
      def perform(object)
        # TODO: Somewhere this variable must exist in some visible manner beside
        # digging deep into a method chain and asking for a none puplic instance
        # variable.
        resource_factory = Hyrax.query_service.services.first.instance_variable_get(:@resource_factory)

        resource = ::Valkyrie::Persistence::Postgres::ORMConverter.new(object, resource_factory:).convert!
        migrate_thumbnail!(resource:)
        migrate_files!(resource:)
      end

      private

      ##
      # @param path [String] path to the expected thumbnail
      #
      # @return [TrueClass] when the thumbnail at the given path has not been
      #         moved to the Valkyrie storage adapter.
      # @return [FalseClass] when the thumbnail has been moved to the Valkyrie
      #         storage adapter.
      # @see #move_thumbnail_to_backup
      def thumbnail_exists?(path)
        path.present? && File.exist?(path)
      end

      def migrate_thumbnail!(resource:)
        return true # JEREMY and SHANA hacking away
        thumbnail_path = Hyrax::DerivativePath.derivative_path_for_reference(resource, 'thumbnail')
        return unless thumbnail_exists?(thumbnail_path)

        tempfile = Tempfile.new
        tempfile.binmode
        tempfile.write(File.read(thumbnail_path))

        # NOTE: There are published events that may or may not be appropriate
        # for this to call.  It's hard to know, given that ActiveFedora's
        # thumbnail was never a "File" on a FileSet but was a unique creature.
        # With Valkyrie that changes and we have a right and proper
        # "Hyrax::PCDM::File" for the thumbnail.
        Hyrax::ValkyrieUpload.file(
          filename: resource.label,
          file_set: resource,
          io: tempfile,
          use: Hyrax::FileMetadata::Use::THUMBNAIL_IMAGE,
          user: User.find_or_initialize_by(User.user_key_field => resource.depositor)
        )

        move_thumbnail_to_backup(thumbnail_path)
      end

      ##
      # Move the ActiveFedora files out of ActiveFedora's domain and into the
      # configured {Hyrax.storage_adapter}'s domain.
      def migrate_files!(resource:)
        return unless resource.respond_to?(:file_ids)

        files = Hyrax.custom_queries.find_many_file_metadata_by_ids(ids: resource.file_ids)
        files.each do |file|
          # If it doesn't start with fedora, we've likely already migrated it.
          next unless /^fedora:/.match?(file.file_identifier.to_s)

          tempfile = Tempfile.new
          tempfile.binmode
          tempfile.write(URI.open(file.file_identifier.to_s.gsub("fedora:", "http:")).read)

          valkyrie_file = Hyrax.storage_adapter.upload(resource: resource, file: tempfile, original_filename: file.original_filename)
          file.file_identifier = valkyrie_file.id

          Hyrax.persister.save(resource: file)
        end
      end

      ##
      # Move the given file to a backup directory, which is derived by injecting
      # "backup-thumbnails" into the :path after the
      # {Hyrax.config.derivatives_path} and before the other subdirectories.
      #
      # @param path [String]
      def move_thumbnail_to_backup(path)
        base_path = Hyrax.config.derivatives_path
        target_dirname = File.dirname(path).sub(base_path, File.join(base_path, "backup-paths"))
        FileUtils.mkdir_p(target_dirname)
        target = File.join(target_dirname, File.basename(path))
        FileUtils.mv(path, target)
      end
    end
  end
end