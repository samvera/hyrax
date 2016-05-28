class IngestFileJob < ActiveJob::Base
  queue_as CurationConcerns.config.ingest_queue_name

  # @param [FileSet] file_set
  # @param [String] filename the cached file within the CurationConcerns.config.working_path
  # @param [String,NilClass] mime_type
  # @param [User] user
  # @param [String] relation ('original_file')
  def perform(file_set, filename, mime_type, user, relation = 'original_file')
    local_file = File.open(filename, "rb")
    # If mime-type is known, wrap in an IO decorator
    # Otherwise allow Hydra::Works service to determine mime_type
    if mime_type
      local_file = Hydra::Derivatives::IoDecorator.new(local_file)
      local_file.mime_type = mime_type
      local_file.original_name = File.basename(filename)
    end

    # Tell AddFileToFileSet service to skip versioning because versions will be minted by VersionCommitter (called by save_characterize_and_record_committer) when necessary
    Hydra::Works::AddFileToFileSet.call(file_set,
                                        local_file,
                                        relation.to_sym,
                                        versioning: false)

    # Persist changes to the file_set
    file_set.save!

    repository_file = file_set.send(relation.to_sym)

    # Do post file ingest actions
    CurationConcerns::VersioningService.create(repository_file, user)

    # TODO: this is a problem, the file may not be available at this path on another machine.
    # It may be local, or it may be in s3
    CharacterizeJob.perform_later(file_set, repository_file.id)
  end
end
