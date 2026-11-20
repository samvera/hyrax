# frozen_string_literal: true

# Remove this test-app override once Bulkrax resolves token-to-user ownership:
# https://github.com/samvera/bulkrax/issues/1237
module BulkraxDisableTokenAuthentication
  private

  def token_authenticate!
    json_response('invalid', :unauthorized, 'Bulkrax token authentication is temporarily disabled')
  end
end

Rails.application.config.to_prepare do
  Bulkrax::ImportersController.prepend(BulkraxDisableTokenAuthentication)
end
