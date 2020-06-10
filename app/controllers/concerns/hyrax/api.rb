# frozen_string_literal: true
module Hyrax
  module API
    # Generate appropriate json response for +response_type+
    DEFAULT_RESPONSES =
      {
        success: {
          code: 200,
          message: "Request Succeeded",
          description: I18n.t('hyrax.api.success.default')
        }.freeze,
        deleted: {
          code: 200,
          message: I18n.t('hyrax.api.deleted.default')
        }.freeze,
        created: {
          code: 201,
          message: "Created the Resource"
        }.freeze,
        accepted: {
          code: 202,
          message: "Accepted",
          description: I18n.t('hyrax.api.accepted.default')
        }.freeze,
        bad_request: {
          code: 400,
          message: "Bad Request",
          description: I18n.t('hyrax.api.bad_request.default')
        }.freeze,
        unauthorized: {
          code: 401,
          message: "Authentication Required",
          description: I18n.t('hyrax.api.unauthorized.default')
        }.freeze,
        forbidden: {
          code: 403,
          message: "Not Authorized",
          description: I18n.t('hyrax.api.forbidden.default')
        }.freeze,
        not_found: {
          code: 404,
          message: "Resource not found",
          description: I18n.t('hyrax.api.not_found.default')
        }.freeze,
        unprocessable_entity: {
          code: 422,
          message: "Unprocessable Entity",
          description: I18n.t('hyrax.api.unprocessable_entity.default'),
          errors: {}
        }.freeze,
        internal_error: {
          code: 500,
          message: "Internal Server Error",
          description: I18n.t('hyrax.api.internal_error.default')
        }.freeze
      }.freeze

    def self.generate_response_body(response_type: :success, message: nil, options: {})
      json_body = default_responses[response_type].merge(options)
      json_body[:description] = message if message
      json_body
    end

    # Default (json) responses for various response types
    def self.default_responses
      DEFAULT_RESPONSES
    end
  end
end
