# frozen_string_literal: true
require 'google/cloud/errors'

module Hyrax
  class StatsController < ApplicationController
    include Hyrax::SingularSubresourceController
    include Hyrax::Breadcrumbs

    # Error class => key under hyrax.stats.analytics_hints. Keys in SHARED_ERROR_TYPES reuse the matching hyrax.admin.analytics.errors title and steps.
    ANALYTICS_ERROR_HINTS = {
      Google::Cloud::PermissionDeniedError => 'permission',
      Google::Cloud::UnauthenticatedError => 'authentication',
      Google::Cloud::InvalidArgumentError => 'invalid_property',
      Google::Cloud::NotFoundError => 'invalid_property',
      Google::Cloud::ResourceExhaustedError => 'quota_exceeded'
    }.freeze
    SHARED_ERROR_TYPES = %w[permission authentication invalid_property quota_exceeded].freeze

    rescue_from Google::Cloud::Error, with: :analytics_unavailable

    before_action :build_breadcrumbs, only: [:work, :file]

    def work
      @document = ::SolrDocument.find(params[:id])
      @pageviews = Hyrax::Analytics.daily_events_for_id(@document.id, 'work-view')
      @downloads = Hyrax::Analytics.daily_events_for_id(@document.id, 'file-set-in-work-download')
    end

    def file
      @stats = Hyrax::FileUsage.new(params[:id])
      @stats.to_flot # load now so a Google failure is rescued here, not mid-render
    end

    private

    # Show zeroed stats and a notice instead of a 500 when Google rejects the request.
    def analytics_unavailable(exception)
      Rails.logger.error "Analytics error: #{exception.message}"
      # Anyone who can read a work can open its stats; only admins get the setup steps.
      if can?(:read, :admin_dashboard)
        @analytics_error = analytics_error_details(exception)
      else
        @analytics_unavailable = true
      end
      if action_name == 'file'
        (@stats ||= Hyrax::FileUsage.new(params[:id])).without_analytics
      else
        @document ||= ::SolrDocument.find(params[:id])
        @pageviews = @downloads = Hyrax::Analytics::Results.new([])
      end
      render action_name
    end

    def analytics_error_details(exception)
      hint = analytics_hint_key(exception)
      scope = "hyrax.admin.analytics.errors.#{SHARED_ERROR_TYPES.include?(hint) ? hint : 'general'}"
      { title: I18n.t('title', scope: scope),
        message: I18n.t('message', scope: scope),
        troubleshooting_steps: Array.wrap(I18n.t('troubleshooting_steps', scope: scope)) + [I18n.t(hint, scope: 'hyrax.stats.analytics_hints')],
        documentation_url: I18n.t('documentation_url', scope: scope),
        details: exception.class.name }
    end

    def analytics_hint_key(exception)
      ANALYTICS_ERROR_HINTS.find { |error_class, _hint| exception.is_a?(error_class) }&.last || 'general'
    end

    def add_breadcrumb_for_controller
      add_breadcrumb I18n.t('hyrax.dashboard.my.works'), hyrax.my_works_path
    end

    def add_breadcrumb_for_action
      case action_name
      when 'file'
        add_breadcrumb I18n.t("hyrax.file_set.browse_view"), main_app.hyrax_file_set_path(params["id"])
      when 'work'
        add_breadcrumb @work.title.first, main_app.polymorphic_path(@work)
      end
    end
  end
end
