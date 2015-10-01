class IngestLocalFileJob < ActiveJob::Base
  attr_accessor :directory, :filename, :user_key, :generic_file_id

  queue_as :ingest_local

  def perform(generic_file_id, directory, filename, user_key)
    @generic_file_id = generic_file_id
    @directory = directory
    @filename = filename
    @user_key = user_key

    user = User.find_by_user_key(user_key)
    fail "Unable to find user for #{user_key}" unless user
    generic_file = GenericFile.find(generic_file_id)
    generic_file.label ||= filename
    path = File.join(directory, filename)

    actor = CurationConcerns::GenericFileActor.new(generic_file, user)

    if actor.create_content(File.open(path))
      FileUtils.rm(path)

      # send message to user on import success
      if CurationConcerns.config.respond_to?(:after_import_local_file_success)
        CurationConcerns.config.after_import_local_file_success.call(generic_file, user, filename)
      end
    else

      # send message to user on import failure
      if CurationConcerns.config.respond_to?(:after_import_local_file_failure)
        CurationConcerns.config.after_import_local_file_failure.call(generic_file, user, filename)
      end
    end
  end
end
