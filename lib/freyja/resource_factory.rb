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

        # NOTE: Should we pass the object and re-convert it?  We'll see how this all
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

        migrate_derivatives!(resource:)
        migrate_files!(resource:)
      end

      private

      def migrate_derivatives!(resource:)
        member_ids = resource.member_ids
        members = Hyrax.query_service.find_many_by_ids(ids: member_ids)

        members.each do |object|
          # @todo should we trigger a job if the member is a child work?
          next unless object.is_a?(FileSet) || object.is_a?(Hyrax::FileSet)

          paths = Hyrax::DerivativePath.derivatives_for_reference(object)
          paths.each do |path|
            next unless path.present?
            path.each_child do |file|
              file_path = path + '/' + file
              content = File.read(file_path)
              container = container_for(file)
              mime_type = Marcel::MimeType.for(extension: File.extname(file))
              directives = { url: file_path, container: container, mime_type: mime_type }
              Hyrax::ValkyriePersistDerivatives.call(content, directives)

              move_derivative_to_backup(file_path)
            end
          end
        end
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
      # "backup-paths" into the :path after the
      # {Hyrax.config.derivatives_path} and before the other subdirectories.
      #
      # @param path [String]
      def move_derivative_to_backup(path)
        base_path = Hyrax.config.derivatives_path
        target_dirname = File.dirname(path).sub(base_path, File.join(base_path, "backup-paths"))
        FileUtils.mkdir_p(target_dirname)
        target = File.join(target_dirname, File.basename(path))
        FileUtils.mv(path, target)
      end

      ##
      # Map from the file name used for the derivative to a valid option for
      # container that ValkyriePersistDerivatives can convert into a 
      # Hyrax::Metadata::Use
      #
      # @param filename [String] the name of the derivative file: i.e. 'x-thumbnail.jpg'
      # @return [String]
      def container_for(filename)
        # we want the portion between the '-' and the '.'
        file_blob = File.basename(file.split('-').last,'.*')

        case file_blob
        when 'thumbnail'
          'thumbnail_image'
        when 'txt', 'json', 'xml'
          'extracted_text'
        else
          'service_file'
        end
      end
    end
  end
end
