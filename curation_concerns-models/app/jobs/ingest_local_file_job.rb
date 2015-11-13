class IngestLocalFileJob < ActiveJob::Base
  queue_as :ingest_local

  def perform(file_set_id, directory, filename, user_key)
    user = User.find_by_user_key(user_key)
    fail "Unable to find user for #{user_key}" unless user
    file_set = FileSet.find(file_set_id)
    file_set.label ||= filename
    path = File.join(directory, filename)

    actor = CurationConcerns::FileSetActor.new(file_set, user)

    if actor.create_content(File.open(path))
      FileUtils.rm(path)
      CurationConcerns.config.callback.run(:after_import_local_file_success, file_set, user, filename)
    else
      CurationConcerns.config.callback.run(:after_import_local_file_failure, file_set, user, filename)
    end
  end
end
