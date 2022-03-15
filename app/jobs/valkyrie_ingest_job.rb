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
  # @param [RDF::URI] pcdm_use is the use/type to apply to the created FileMetadata
  # @see Hyrax::FileMetadata::Use
  def perform(file, pcdm_use: Hyrax::FileMetadata::Use::ORIGINAL_FILE)
    ingest(file: file, pcdm_use: pcdm_use)
  end

  ##
  # @api private
  #
  # @param [Hyrax::UploadedFile] file
  # @param [RDF::URI] pcdm_use

  # @return [void]
  def ingest(file:, pcdm_use:)
    file_set_uri = Valkyrie::ID.new(file.file_set_uri)
    file_set = Hyrax.query_service.find_by(id: file_set_uri)

    updated_metadata = upload_file(file: file, file_set: file_set, pcdm_use: pcdm_use)

    add_file_to_file_set(file_set: file_set,
                         file_metadata: updated_metadata,
                         user: file.user)

    ValkyrieCreateDerivativesJob.perform_later(file_set.id.to_s, updated_metadata.id.to_s)
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
    set_file_use_ids(file_set, file_metadata)

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
  def upload_file(file:, file_set:, pcdm_use:) # rubocop:disable Metrics/MethodLength
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

    if pcdm_use == Hyrax::FileMetadata::Use::ORIGINAL_FILE
      # Set file set label.
      reset_title = file_set.title.first == file_set.label
      # set title to label if that's how it was before this characterization
      file_set.title = file_metadata.original_filename if reset_title
      # always set the label to the original_name
      file_set.label = file_metadata.original_filename
    end

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

  ##
  # @api private
  def set_file_use_ids(file_set, file_metadata)
    file_metadata.type.each do |type|
      case type
      when Hyrax::FileMetadata::Use::ORIGINAL_FILE
        file_set.original_file_id = file_metadata.id
      when Hyrax::FileMetadata::Use::THUMBNAIL
        file_set.thumbnail_id = file_metadata.id
      when Hyrax::FileMetadata::Use::EXTRACTED_TEXT
        file_set.extracted_text_id = file_metadata.id
      else
        Rails.logger.warn "Unknown file use #{file_metadata.type} specified for #{file_metadata.file_identifier}"
      end
    end
  end
end
