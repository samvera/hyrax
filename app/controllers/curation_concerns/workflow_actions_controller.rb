module CurationConcerns
  class WorkflowActionsController < ApplicationController
    before_action :authenticate_user!

    def update
      work = ActiveFedora::Base.find(params[:id])
      if save_workflow_form_for(work: work)
        redirect_to [main_app, work], notice: "The #{work.human_readable_type} has been updated."
      else
        render 'curation_concerns/base/unauthorized', status: :unauthorized
      end
    end

    private

      def workflow_action_params
        params.require(:workflow_action).permit(:name, :comment)
      end

      def save_workflow_form_for(work:)
        CurationConcerns::Forms::WorkflowActionForm.save(
          current_ability: current_ability, work: work, workflow_action: workflow_action_params
        )
      end
  end
end
