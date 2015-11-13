class IngestFileJob < ActiveJob::Base
  queue_as :ingest

  def perform(file_set_id, filename, mime_type, user_key)
    file_set = FileSet.find(file_set_id)

    file = File.open(filename, "rb")
    # If mime-type is known, wrap in an IO decorator
    # Otherwise allow Hydra::Works service to determine mime_type
    if mime_type
      file = Hydra::Derivatives::IoDecorator.new(file)
      file.mime_type = mime_type
      file.original_name = File.basename(filename)
    end

    # Tell AddFileToFileSet service to skip versioning because versions will be minted by VersionCommitter (called by save_characterize_and_record_committer) when necessary
    Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file, versioning: false)

    # Persist changes to the file_set
    file_set.save!

    # Do post file ingest actions
    user = User.find_by_user_key(user_key)
    CurationConcerns::VersioningService.create(file_set.original_file, user)
    CurationConcerns.config.callback.run(:after_create_content, file_set, user)
  end
end
