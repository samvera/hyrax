module Hyrax
  class StatsController < ApplicationController
    include Hyrax::Breadcrumbs
    include DenyAccessOverrideBehavior

    before_action :load_and_authorize_work, only: :work
    before_action :load_and_authorize_file_set, only: :file
    before_action :build_breadcrumbs, only: [:work, :file]

    def work
      @stats = Hyrax::WorkUsage.new(params[:id])
    end

    def file
      @stats = Hyrax::FileUsage.new(params[:id])
    end

    private

      def load_and_authorize_work
        resource = Hyrax::Queries.find_by(id: Valkyrie::ID.new(params[:id]))
        raise Hyrax::ObjectNotFoundError("Couldn't find work with 'id'=#{params[:id]}") unless resource.work?
        @work = resource
        authorize! :stats, @work
      end

      def load_and_authorize_file_set
        resource = Hyrax::Queries.find_by(id: Valkyrie::ID.new(params[:id]))
        raise Hyrax::ObjectNotFoundError("Couldn't find file set with 'id'=#{params[:id]}") unless resource.file_set?
        @file_set = resource
        authorize! :stats, @file_set
      end

      def add_breadcrumb_for_controller
        add_breadcrumb I18n.t('hyrax.dashboard.my.works'), hyrax.my_works_path
      end

      def add_breadcrumb_for_action
        case action_name
        when 'file'.freeze
          add_breadcrumb I18n.t("hyrax.file_set.browse_view"), main_app.hyrax_file_set_path(params["id"])
        when 'work'.freeze
          add_breadcrumb @work.to_s, main_app.polymorphic_path(@work)
        end
      end
  end
end
