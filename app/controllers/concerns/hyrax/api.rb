module Hyrax
  module API
    # Generate appropriate json response for +response_type+

    def self.generate_response_body(response_type: :success, message: nil, options: {})
      json_body = default_responses[response_type].merge(options)
      json_body[:description] = message if message
      json_body
    end

    # Default (json) responses for various response types
    def self.default_responses
      {
        success: {
          code: 200,
          message: "Request Succeeded",
          description: I18n.t('hyrax.api.success.default')
        },
        deleted: {
          code: 200,
          message: I18n.t('hyrax.api.deleted.default')
        },
        created: {
          code: 201,
          message: "Created the Resource"
        },
        accepted: {
          code: 202,
          message: "Accepted",
          description: I18n.t('hyrax.api.accepted.default')
        },
        bad_request: {
          code: 400,
          message: "Bad Request",
          description: I18n.t('hyrax.api.bad_request.default')
        },
        unauthorized: {
          code: 401,
          message: "Authentication Required",
          description: I18n.t('hyrax.api.unauthorized.default')
        },
        forbidden: {
          code: 403,
          message: "Not Authorized",
          description: I18n.t('hyrax.api.forbidden.default')
        },
        not_found: {
          code: 404,
          message: "Resource not found",
          description: I18n.t('hyrax.api.not_found.default')
        },
        unprocessable_entity: {
          code: 422,
          message: "Unprocessable Entity",
          description: I18n.t('hyrax.api.unprocessable_entity.default'),
          errors: {}
        },
        internal_error: {
          code: 500,
          message: "Internal Server Error",
          description: I18n.t('hyrax.api.internal_error.default')
        }
      }
    end
  end
end
