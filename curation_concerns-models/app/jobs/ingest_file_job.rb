class IngestFileJob < ActiveJob::Base
  queue_as :ingest

  def perform(file_set_id, filename, mime_type, user_key)
    file_set = FileSet.find(file_set_id)
    file = Hydra::Derivatives::IoDecorator.new(File.open(filename, "rb"))
    file.mime_type = mime_type
    file.original_name = File.basename(filename)

    # Tell UploadFileToGenericFile service to skip versioning because versions will be minted by VersionCommitter (called by save_characterize_and_record_committer) when necessary
    Hydra::Works::UploadFileToFileSet.call(file_set, file, versioning: false)
    file_set.save!
    CurationConcerns::VersioningService.create(file_set.original_file, user_key)
    CurationConcerns.config.callback.run(:after_create_content, file_set, user_key)
  end
end
