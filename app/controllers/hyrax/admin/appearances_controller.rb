module Hyrax
  module Admin
    class AppearancesController < ApplicationController
      before_action :require_permissions
      with_themed_layout 'dashboard'
      class_attribute :change_set_class
      self.change_set_class = Hyrax::Forms::Admin::Appearance

      def show
        add_breadcrumb t(:'hyrax.controls.home'), root_path
        add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
        add_breadcrumb t(:'hyrax.admin.sidebar.configuration'), '#'
        add_breadcrumb t(:'hyrax.admin.sidebar.appearance'), request.path
        @form = change_set_class.new
      end

      def update
        change_set_class.new(update_params).update!
        redirect_to({ action: :show }, notice: t('.flash.success'))
      end

      private

        def update_params
          params.require(:admin_appearance).permit(change_set_class.permitted_params)
        end

        def require_permissions
          authorize! :update, :appearance
        end
    end
  end
end
