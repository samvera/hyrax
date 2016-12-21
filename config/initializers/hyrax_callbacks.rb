# These events are triggered by actions within Hyrax Actors
Hyrax.config.callback.set(:after_create_concern) do |curation_concern, user|
  ContentDepositEventJob.perform_later(curation_concern, user)
end

Hyrax.config.callback.set(:after_create_fileset) do |file_set, user|
  FileSetAttachedEventJob.perform_later(file_set, user)
end

Hyrax.config.callback.set(:after_revert_content) do |file_set, user, revision|
  ContentRestoredVersionEventJob.perform_later(file_set, user, revision)
end

Hyrax.config.callback.set(:after_update_content) do |file_set, user|
  ContentNewVersionEventJob.perform_later(file_set, user)
end

Hyrax.config.callback.set(:after_update_metadata) do |curation_concern, user|
  ContentUpdateEventJob.perform_later(curation_concern, user)
end

Hyrax.config.callback.set(:after_destroy) do |id, user|
  ContentDeleteEventJob.perform_later(id, user)
end

Hyrax.config.callback.set(:after_audit_failure) do |file_set, user, log_date|
  Hyrax::AuditFailureService.new(file_set, user, log_date).call
end

Hyrax.config.callback.set(:after_batch_create_success) do |user|
  Hyrax::BatchCreateSuccessService.new(user).call
end

Hyrax.config.callback.set(:after_batch_create_failure) do |user|
  Hyrax::BatchCreateFailureService.new(user).call
end

Hyrax.config.callback.set(:after_import_url_success) do |file_set, user|
  Hyrax::ImportUrlSuccessService.new(file_set, user).call
end

Hyrax.config.callback.set(:after_import_url_failure) do |file_set, user|
  Hyrax::ImportUrlFailureService.new(file_set, user).call
end
