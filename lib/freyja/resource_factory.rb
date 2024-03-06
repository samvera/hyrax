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
        unless thumbnail_path_moved?(thumbnail)

          if thumbnail.present? && File.exist?(thumbnail)
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

    def thumbnail_path_moved?(thumbnail)

    end

    def move_thumbnail_to_backup(thumbnail)

    end
  end
end