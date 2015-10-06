class IngestLocalFileJob < ActiveJob::Base
  attr_accessor :directory, :filename, :user_key, :file_set_id

  queue_as :ingest_local

  def perform(file_set_id, directory, filename, user_key)
    @file_set_id = file_set_id
    @directory = directory
    @filename = filename
    @user_key = user_key

    user = User.find_by_user_key(user_key)
    fail "Unable to find user for #{user_key}" unless user
    file_set = FileSet.find(file_set_id)
    file_set.label ||= filename
    path = File.join(directory, filename)

    actor = CurationConcerns::FileSetActor.new(file_set, user)

    if actor.create_content(File.open(path))
      FileUtils.rm(path)

      # send message to user on import success
      if CurationConcerns.config.respond_to?(:after_import_local_file_success)
        CurationConcerns.config.after_import_local_file_success.call(file_set, user, filename)
      end
    else

      # send message to user on import failure
      if CurationConcerns.config.respond_to?(:after_import_local_file_failure)
        CurationConcerns.config.after_import_local_file_failure.call(file_set, user, filename)
      end
    end
  end
end
