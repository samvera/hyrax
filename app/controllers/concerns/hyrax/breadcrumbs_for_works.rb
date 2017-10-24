module Hyrax
  module BreadcrumbsForWorks
    extend ActiveSupport::Concern
    include Hyrax::Breadcrumbs

    included do
      # We don't want the breadcrumb action to occur until after the concern has
      # been loaded and authorized
      after_action :build_breadcrumbs, only: [:edit, :show, :new]
    end

    private

      def build_breadcrumbs
        return super if action_name == 'show'
        # These breadcrumbs are for the edit/create actions
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb_for_controller
        add_breadcrumb_for_action
      end

      def add_breadcrumb_for_controller
        add_breadcrumb I18n.t(:'hyrax.dashboard.my.works'), hyrax.my_works_path
      end

      def add_breadcrumb_for_action
        case action_name
        when 'edit'.freeze
          add_breadcrumb @change_set.resource.to_s, main_app.polymorphic_path(@change_set.resource)
          add_breadcrumb t(:'hyrax.works.edit.breadcrumb'), request.path
        when 'new'.freeze
          add_breadcrumb t(:'hyrax.works.create.breadcrumb'), request.path
        when 'show'.freeze
          add_breadcrumb presenter.to_s, main_app.polymorphic_path(presenter)
        end
      end
  end
end
