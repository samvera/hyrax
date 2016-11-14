module CurationConcerns
  module Admin
    class WorkflowRolesController < ApplicationController
      include AdminPage
      before_action :require_permissions

      def index
        @presenter = WorkflowRolePresenter.new
      end

      def destroy
        responsibility = Sipity::WorkflowResponsibility.find(params[:id])
        authorize! :destroy, responsibility
        responsibility.destroy
        redirect_to admin_workflow_roles_path
      end

      def create
        authorize! :create, Sipity::WorkflowResponsibility
        form = Forms::WorkflowResponsibilityForm.new(params[:sipity_workflow_responsibility])
        begin
          form.save!
        rescue ActiveRecord::RecordNotUnique
          logger.info "Not unique *****\n\n\n"
        end
        redirect_to admin_workflow_roles_path
      end

      private

        def require_permissions
          authorize! :read, :admin_dashboard
        end
    end
  end
end
