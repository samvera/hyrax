class StatsController < ApplicationController
  include Sufia::SingularSubresourceController
  include Sufia::Breadcrumbs

  before_action :build_breadcrumbs, only: [:work, :file]

  def work
    @stats = Sufia::WorkUsage.new(params[:id])
  end

  def file
    @stats = Sufia::FileUsage.new(params[:id])
  end

  protected

    def add_breadcrumb_for_controller
      add_breadcrumb I18n.t('sufia.dashboard.my.works'), sufia.dashboard_works_path
    end

    def add_breadcrumb_for_action
      case action_name
      when 'file'.freeze
        add_breadcrumb I18n.t("sufia.file_set.browse_view"), main_app.curation_concerns_file_set_path(params["id"])
      when 'work'.freeze
        add_breadcrumb @work.to_s, polymorphic_path(@work)
      end
    end
end
