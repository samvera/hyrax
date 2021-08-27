# frozen_string_literal: true
module Hyrax
  class StatsController < ApplicationController
    include Hyrax::SingularSubresourceController
    include Hyrax::Breadcrumbs

    before_action :build_breadcrumbs, only: [:work, :file]

    def work
      # @stats = Hyrax::WorkUsage.new(params[:id])
      @document = ::SolrDocument.find(params[:id])
      path = main_app.send("hyrax_#{@document._source['has_model_ssim'].first.underscore}s_path", params[:id]).sub('.', '/')
      path = request.base_url + path if Hyrax.config.analytics_provider == 'matomo'
      @pageviews = Hyrax::Analytics.pageviews_for_url(path)
      @downloads = Hyrax::Analytics.downloads_for_id(params[:id])
    end

    def file
      @stats = Hyrax::FileUsage.new(params[:id])
    end

    private

    def add_breadcrumb_for_controller
      add_breadcrumb I18n.t('hyrax.dashboard.my.works'), hyrax.my_works_path
    end

    def add_breadcrumb_for_action
      case action_name
      when 'file'
        add_breadcrumb I18n.t("hyrax.file_set.browse_view"), main_app.hyrax_file_set_path(params["id"])
      when 'work'
        add_breadcrumb @work.to_s, main_app.polymorphic_path(@work)
      end
    end
  end
end
