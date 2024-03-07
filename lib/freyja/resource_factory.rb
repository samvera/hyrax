# frozen_string_literal: true

module Freyja
  # Provides access to generic methods for converting to/from
  # {Valkyrie::Resource} and {Valkyrie::Persistence::Postgres::ORM::Resource}.
  class ResourceFactory < Valkyrie::Persistence::Postgres::ResourceFactory
    # @param object [Valkyrie::Persistence::Postgres::ORM::Resource] AR
    #   record to be converted.
    # @return [Valkyrie::Resource] Model representation of the AR record.
    def to_resource(object:)
      resource = ::Valkyrie::Persistence::Postgres::ORMConverter.new(object, resource_factory: self).convert!

      if resource.respond_to?(:file_ids) # this is a filset if it responds to file_ids
        # use path from downloads controller. check file. if it exists, upload the file to valkyrie. 
        # 1. move file into backup directory (that we need to create)
        # 2. upload it to valkyrie with the thumbnail use
        #  GOAL: persist a file - 
        # check if we've already migrated the thumbnail 
        # if we have, don't do the following logic
        
        # thumbnail section
        # get a temp file of the thumbnail (copy)
        # we want a valkyrie file using the valkyrie upload 
        thumbnail = Hyrax::DerivativePath.derivative_path_for_reference(resource, 'thumbnail') # if this includes the backup directory, don't do the next bit of work
        # target should be based off of the above path
        unless thumbnail_exists?(thumbnail)

          tempfile = Tempfile.new
          tempfile.binmode
          tempfile.write(File.read(thumbnail))

          Hyrax::ValkyrieUpload.file(
            filename: resource.label,
            file_set: resource,
            io: tempfile,
            use: Hyrax::FileMetadata::Use::THUMBNAIL_IMAGE,
            user: User.find_or_initialize_by(User.user_key_field => resource.depositor)
          )
          move_thumbnail_to_backup(thumbnail)
        end

        # files section
        files = Hyrax.custom_queries.find_many_file_metadata_by_ids(ids: resource.file_ids)
        files.each do |file|
          next unless /^fedora:/.match?(file.file_identifier.to_s)

          tempfile = Tempfile.new
          tempfile.binmode
          tempfile.write(URI.open(file.file_identifier.to_s.gsub("fedora:", "http:")).read)

          valkyrie_file = Hyrax.storage_adapter.upload(resource: resource, file: tempfile, original_filename: file.original_filename)
          file.file_identifier = valkyrie_file.id

          Hyrax.persister.save(resource: file)
        end
      end

      super
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

    ##
    # Move the given file to a backup directory, which is derived by injecting
    # "backup-thumbnails" into the :path after the
    # {Hyrax.config.derivatives_path} and before the other subdirectories.
    #
    # @param path [String]
    def move_thumbnail_to_backup(path)
      # Don't move what's not there.
      return unless thumbnail_exists?(path)

      base_path = Hyrax.config.derivatives_path
      target_dirname = File.dirname(path).sub(base_path, File.join(base_path, "backup-paths"))
      FileUtils.mkdir_p(target_dirname)
      target = File.join(target_dirname, File.basename(path))
      FileUtils.mv(path, target)
    end
  end
end
