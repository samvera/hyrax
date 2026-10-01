# frozen_string_literal: true
require 'google/cloud/errors'

module Hyrax
  class StatsController < ApplicationController
    include Hyrax::SingularSubresourceController
    include Hyrax::Breadcrumbs

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
      @analytics_error = analytics_error_details(exception)
      if action_name == 'file'
        @stats = Hyrax::FileUsage.new(params[:id]).tap(&:without_analytics)
      else
        @document ||= ::SolrDocument.find(params[:id])
        @pageviews = @downloads = Hyrax::Analytics::Results.new([])
      end
      render action_name
    end

    def analytics_error_details(exception)
      type = exception.is_a?(Google::Cloud::PermissionDeniedError) ? 'permission' : 'general'
      scope = "hyrax.admin.analytics.errors.#{type}"
      { title: I18n.t('title', scope: scope),
        message: I18n.t('message', scope: scope),
        troubleshooting_steps: Array.wrap(I18n.t('troubleshooting_steps', scope: scope)),
        documentation_url: I18n.t('documentation_url', scope: scope),
        details: exception.message }
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
