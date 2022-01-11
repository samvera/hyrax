# frozen_string_literal: true
class ValkyrieIngestJob < Hyrax::ApplicationJob
  queue_as Hyrax.config.ingest_queue_name

  ##
  # @param [Valkyrie::StorageAdapter::StreamFile] file
  def perform(file)
    ingest(file: file)
  end

  ##
  # @param [Valkyrie::StorageAdapter::StreamFile] file
  #
  # @return [void]
  def ingest(file:)
    file_set = Hyrax.query_service.find_by(id: file.file_set_uri)
    file_metadata = Hyrax::FileMetadata.for(file: file.uploader.file)

    updated_metadata = upload_file(file: file, file_metadata: file_metadata, file_set: file_set)
    add_file_to_file_set(file_set: file_set, file_metadata: updated_metadata)
  end

  ##
  # @todo this should publish something to allow the fileset
  #   to reindex its membership
  # @param [Hyrax::FileSet] file_set the file set to add to
  # @param [Hyrax::FileMetadata] file_metadata the metadata object representing
  #   the file to add
  #
  # @return [Hyrax::FileSet] updated file set
  def add_file_to_file_set(file_set:, file_metadata:)
    file_set.file_ids << file_metadata.id
    Hyrax.persister.save(resource: file_set)
  end

  # @param [Hyrax::UploadedFile] file
  # @param [Hyrax::FileMetadata] file_metadata
  # @param [Hyrax::FileSet] file_set
  # @return Hyrax::FileMetadata uploaded file
  def upload_file(file:, file_metadata:, file_set:)
    uploader = file.uploader
    file_metadata.file_set_id = file.file_set_uri
    uploaded = Hyrax.storage_adapter
                    .upload(resource: file_set,
                            file: File.open(uploader.file.file),
                            original_filename: file_metadata.original_filename)
    file_metadata.file_identifier = uploaded.id
    file_metadata.size = uploaded.size

    Hyrax.publisher.publish(
      "object.file.uploaded",
      metadata: file_metadata
    )

    file_metadata
  end
end
