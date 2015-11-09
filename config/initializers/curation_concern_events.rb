# These events are triggered by actions within CurationConcerns Actors
CurationConcerns.config.callback.set(:after_create_content) do |file_set, user|
  CurationConcerns.queue.push(ContentDepositEventJob.new(file_set.id, user.user_key))
end

CurationConcerns.config.callback.set(:after_revert_content) do |file_set, user, revision|
  CurationConcerns.queue.push(ContentRestoredVersionEventJob.new(file_set.id, user.user_key, revision))
end

CurationConcerns.config.callback.set(:after_update_content) do |file_set, user|
  CurationConcerns.queue.push(ContentNewVersionEventJob.new(file_set.id, user.user_key))
end

CurationConcerns.config.callback.set(:after_update_metadata) do |file_set, user|
  CurationConcerns.queue.push(ContentUpdateEventJob.new(file_set.id, user.user_key))
end

CurationConcerns.config.callback.set(:after_destroy) do |id, user|
  CurationConcerns.queue.push(ContentDeleteEventJob.new(id, user.user_key))
end

CurationConcerns.config.callback.set(:after_audit_failure) do |file_set, user, log_date|
  Sufia::AuditFailureService.new(file_set, user, log_date).call
end

CurationConcerns.config.callback.set(:after_import_url_success) do |file_set, user|
  Sufia::ImportUrlSuccessService.new(file_set, user).call
end

CurationConcerns.config.callback.set(:after_import_url_failure) do |file_set, user|
  Sufia::ImportUrlFailureService.new(file_set, user).call
end

CurationConcerns.config.callback.set(:after_import_local_file_success) do |file_set, user, filename|
  Sufia::ImportLocalFileSuccessService.new(file_set, user, filename).call
end

CurationConcerns.config.callback.set(:after_import_local_file_failure) do |file_set, user, filename|
  Sufia::ImportLocalFileFailureService.new(file_set, user, filename).call
end
