# frozen_string_literal: true

##
# Ingests a {Hyrax::UploadedFile} as file member of a {Hyrax::FileSet}.
#
# The {Hyrax::UploadedFile} is passed into {#perform}, and should have a
# {Hyrax::UploadedFile#file_set_uri} identifying an existing {Hyrax::FileSet}.
class ValkyrieIngestJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  ##
  # @param [Hyrax::UploadedFile] file
  def perform(file)
    ingest(file: file)
  end

  ##
  # @api private
  #
  # @param [Hyrax::UploadedFile] file
  #
  # @return [void]
  def ingest(file:)
    file_set_uri = Valkyrie::ID.new(file.file_set_uri)
    file_set = Hyrax.query_service.find_by(id: file_set_uri)

    updated_metadata = upload_file(file: file, file_set: file_set)

    add_file_to_file_set(file_set: file_set,
                         file_metadata: updated_metadata,
                         user: file.user)
  end

  ##
  # @api private
  #
  # @param [Hyrax::FileSet] file_set the file set to add to
  # @param [Hyrax::FileMetadata] file_metadata the metadata object representing
  #   the file to add
  # @param [::User] user  the user performing the add
  #
  # @return [Hyrax::FileSet] updated file set
  def add_file_to_file_set(file_set:, file_metadata:, user:)
    file_set.file_ids << file_metadata.id
    Hyrax.persister.save(resource: file_set)
    Hyrax.publisher.publish('object.membership.updated', object: file_set, user: user)
  end

  ##
  # @api private
  #
  # @param [Hyrax::UploadedFile] file
  # @param [Hyrax::FileSet] file_set
  # @param [RDF::URI] pcdm_use  the use/type to apply to the created FileMetadata
  #
  # @return [Hyrax::FileMetadata] the metadata representing the uploaded file
  def upload_file(file:, file_set:, pcdm_use: Hyrax::FileMetadata::Use::ORIGINAL_FILE)
    carrier_wave_sanitized_file = file.uploader.file
    # Pull file, since carrierwave files don't respond to a proper IO #read. See
    # https://github.com/carrierwaveuploader/carrierwave/issues/1959
    file_io = carrier_wave_sanitized_file.to_file
    uploaded = Hyrax.storage_adapter
                    .upload(resource: file_set,
                            file: file_io,
                            original_filename: carrier_wave_sanitized_file.original_filename)

    file_metadata = find_or_create_metadata(id: uploaded.id, file: carrier_wave_sanitized_file)

    file_metadata.type << pcdm_use
    file_metadata.file_set_id = file.file_set_uri
    file_metadata.file_identifier = uploaded.id
    file_metadata.size = uploaded.size

    saved_metadata = Hyrax.persister.save(resource: file_metadata)
    Hyrax.publisher.publish("object.file.uploaded", metadata: saved_metadata)
    file_io.close

    saved_metadata
  end

  ##
  # @api private
  def find_or_create_metadata(id:, file:)
    Hyrax.custom_queries.find_file_metadata_by(id: id)
  rescue Valkyrie::Persistence::ObjectNotFoundError => e
    Hyrax.logger.warn "Failed to find existing metadata for #{id}:"
    Hyrax.logger.warn e.message
    Hyrax.logger.warn "Creating Hyrax::FileMetadata now"
    Hyrax::FileMetadata.for(file: file)
  end
end
