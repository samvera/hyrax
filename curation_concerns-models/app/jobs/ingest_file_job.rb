class IngestFileJob < ActiveJob::Base
  queue_as :ingest

  def perform(generic_file_id, filename, mime_type, user_key)
    generic_file = GenericFile.find(generic_file_id)
    file = Hydra::Derivatives::IoDecorator.new(File.open(filename, "rb"))
    file.mime_type = mime_type
    file.original_name = File.basename(filename)

    # Tell UploadFileToGenericFile service to skip versioning because versions will be minted by VersionCommitter (called by save_characterize_and_record_committer) when necessary
    Hydra::Works::UploadFileToGenericFile.call(generic_file, file, versioning: false)
    generic_file.save!
    CurationConcerns::VersioningService.create(generic_file.original_file, user_key)

    return unless CurationConcerns.config.respond_to?(:after_create_content)
    CurationConcerns.config.after_create_content.call(generic_file, user_key)
  end
end
