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

# :after_update_content callback replaced by after_perform block in IngestJob

Hyrax.config.callback.set(:after_update_metadata) do |curation_concern, user|
  ContentUpdateEventJob.perform_later(curation_concern, user)
end

Hyrax.config.callback.set(:after_destroy) do |id, user|
  ContentDeleteEventJob.perform_later(id, user)
end

Hyrax.config.callback.set(:after_fixity_check_failure) do |file_set, checksum_audit_log:|
  Hyrax::FixityCheckFailureService.new(file_set, checksum_audit_log: checksum_audit_log).call
end

Hyrax.config.callback.set(:after_batch_create_success) do |user|
  Hyrax::BatchCreateSuccessService.new(user).call
end

Hyrax.config.callback.set(:after_batch_create_failure) do |user, messages|
  Hyrax::BatchCreateFailureService.new(user, messages).call
end

Hyrax.config.callback.set(:after_import_url_success) do |file_set, user|
  # ImportUrlSuccessService was removed here since it's duplicative of
  # the :after_create_fileset notification
end

Hyrax.config.callback.set(:after_import_url_failure) do |file_set, user|
  Hyrax::ImportUrlFailureService.new(file_set, user).call
end
