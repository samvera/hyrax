# frozen_string_literal: true
module Hyrax
  class StatsController < ApplicationController
    include Hyrax::SingularSubresourceController
    include Hyrax::Breadcrumbs

    before_action :build_breadcrumbs, only: [:work, :file]

    def work
      @document = ::SolrDocument.find(params[:id])
      @pageviews = Hyrax::Analytics.daily_events_for_id(@document.id, 'work-view')
      @downloads = Hyrax::Analytics.daily_events_for_id(@document.id, 'file-set-in-work-download')
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
