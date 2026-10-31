# frozen_string_literal: true
module Hyrax
  module AnalyticsErrorHandling
    extend ActiveSupport::Concern

    # Names, not constants: the Google gems may not be loaded when this concern is.
    ERROR_TYPES_BY_CLASS = {
      'Google::Cloud::PermissionDeniedError' => 'permission',
      'Google::Cloud::UnauthenticatedError' => 'authentication',
      'Google::Cloud::InvalidArgumentError' => 'invalid_property',
      'Google::Cloud::NotFoundError' => 'invalid_property',
      'Google::Cloud::ResourceExhaustedError' => 'quota_exceeded'
    }.freeze

    included do
      rescue_from StandardError, with: :handle_analytics_general_error
    end

    private

    def handle_analytics_general_error(exception)
      raise exception unless analytics_related_error?(exception)

      Rails.logger.error "Analytics error: #{exception.message}"

      error_type = determine_error_type(exception)

      @analytics_error = {
        type: error_type,
        title: I18n.t("hyrax.admin.analytics.errors.#{error_type}.title"),
        message: I18n.t("hyrax.admin.analytics.errors.#{error_type}.message"),
        details: exception.message,
        troubleshooting_steps: Array.wrap(I18n.t("hyrax.admin.analytics.errors.#{error_type}.troubleshooting_steps")),
        documentation_url: I18n.t("hyrax.admin.analytics.errors.#{error_type}.documentation_url")
      }
      set_empty_analytics_data
      render_analytics_with_error
    end

    def determine_error_type(exception)
      exception.class.ancestors.each { |klass| return ERROR_TYPES_BY_CLASS[klass.name] if ERROR_TYPES_BY_CLASS.key?(klass.name) }

      case exception.message
      when /property.*not found/i, /invalid property/i
        'invalid_property'
      when /authentication/i, /credentials/i, /unauthorized/i
        'authentication'
      when /quota/i, /rate limit/i
        'quota_exceeded'
      else
        'general'
      end
    end

    def analytics_related_error?(exception)
      return true if google_cloud_error?(exception)
      exception.message.include?('analytics') ||
        exception.message.include?('Google') ||
        exception.message.include?('property') ||
        exception.backtrace&.any? { |line| line.include?('analytics') || line.include?('google') }
    end

    def google_cloud_error?(exception)
      exception.class.ancestors.any? { |klass| klass.name == 'Google::Cloud::Error' }
    end

    def set_empty_analytics_data
      # Set empty data structures to prevent view errors
      empty_data = { pageviews: [], work_page_views: [], downloads: [], all_top_collections: [],
                     top_collections: [], top_downloads: [], top_collection_pages: [], accessible_works: [],
                     accessible_file_sets: [], works_count: 0, top_works: [], top_file_set_downloads: [],
                     uniques: [], files: [] }

      empty_data.each { |key, value| instance_variable_set("@#{key}", value) if instance_variable_get("@#{key}").nil? }
    end

    def render_analytics_with_error
      respond_to do |format|
        format.html { render :index }
        format.csv { render plain: "Analytics data unavailable due to configuration error", status: :service_unavailable }
      end
    end

    def safe_analytics_call(method_name, *args)
      Hyrax::Analytics.send(method_name, *args)
    rescue StandardError => e
      Rails.logger.warn "#{google_cloud_error?(e) ? 'Analytics call failed' : 'Unexpected analytics error'}: #{method_name} - #{e.message}"
      []
    end
  end
end
