module Hyrax
  # Presents a list of works in workflow
  class Admin::WorkflowsController < ApplicationController
    before_action :ensure_admin!
    layout 'dashboard'

    def index
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.admin.sidebar.tasks'), '#'
      add_breadcrumb t(:'hyrax.admin.sidebar.workflow_review'), request.path
      @status_list = Hyrax::Workflow::StatusListService.new(self, "-workflow_state_name_ssim:#{deposited_workflow_state_name}")
      @published_list = Hyrax::Workflow::StatusListService.new(self, "workflow_state_name_ssim:#{deposited_workflow_state_name}")
    end

    private

      def ensure_admin!
        # Even though the user can view this admin set, they may not be able to view
        # it on the admin page.
        authorize! :read, :admin_dashboard
      end

      def deposited_workflow_state_name
        'deposited'
      end
  end
end
