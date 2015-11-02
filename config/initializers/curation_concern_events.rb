# These events are triggered by actions within CurationConcerns Actors
CurationConcerns.config.callback.set(:after_create_content) do |generic_file, user|
  CurationConcerns.queue.push(ContentDepositEventJob.new(generic_file.id, user.user_key))
end

CurationConcerns.config.callback.set(:after_revert_content) do |generic_file, user, revision|
  CurationConcerns.queue.push(ContentRestoredVersionEventJob.new(generic_file.id, user.user_key, revision))
end

CurationConcerns.config.callback.set(:after_update_content) do |generic_file, user|
  CurationConcerns.queue.push(ContentNewVersionEventJob.new(generic_file.id, user.user_key))
end

CurationConcerns.config.callback.set(:after_update_metadata) do |generic_file, user|
  CurationConcerns.queue.push(ContentUpdateEventJob.new(generic_file.id, user.user_key))
end

CurationConcerns.config.callback.set(:after_destroy) do |id, user|
  CurationConcerns.queue.push(ContentDeleteEventJob.new(id, user.user_key))
end

CurationConcerns.config.callback.set(:after_audit_failure) do |generic_file, user, log_date|
  Sufia::AuditFailureService.new(generic_file, user, log_date).call
end

CurationConcerns.config.callback.set(:after_import_url_success) do |generic_file, user|
  Sufia::ImportUrlSuccessService.new(generic_file, user).call
end

CurationConcerns.config.callback.set(:after_import_url_failure) do |generic_file, user|
  Sufia::ImportUrlFailureService.new(generic_file, user).call
end

CurationConcerns.config.callback.set(:after_import_local_file_success) do |generic_file, user, filename|
  Sufia::ImportLocalFileSuccessService.new(generic_file, user, filename).call
end

CurationConcerns.config.callback.set(:after_import_local_file_failure) do |generic_file, user, filename|
  Sufia::ImportLocalFileFailureService.new(generic_file, user, filename).call
end
