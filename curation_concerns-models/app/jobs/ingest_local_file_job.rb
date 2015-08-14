class IngestLocalFileJob
  attr_accessor :directory, :filename, :user_key, :generic_file_id

  def queue_name
    :ingest
  end

  def initialize(generic_file_id, directory, filename, user_key)
    self.generic_file_id = generic_file_id
    self.directory = directory
    self.filename = filename
    self.user_key = user_key
  end

  def run
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

  def job_user
    User.batchuser
  end

  def mime_type(file_name)
    mime_types = MIME::Types.of(file_name)
    mime_types.empty? ? 'application/octet-stream' : mime_types.first.content_type
  end
end
