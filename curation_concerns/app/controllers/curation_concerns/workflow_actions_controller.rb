module CurationConcerns
  class WorkflowActionsController < ApplicationController
    before_action :authenticate_user!

    def update
      work = ActiveFedora::Base.find(params[:id])
      workflow_action_form = CurationConcerns::Forms::WorkflowActionForm.new(
        current_ability: current_ability,
        work: work,
        attributes: workflow_action_params
      )
      if workflow_action_form.save
        redirect_to [main_app, work], notice: "The #{work.human_readable_type} has been updated."
      else
        render 'curation_concerns/base/unauthorized', status: :unauthorized
      end
    end

    private

      def workflow_action_params
        params.require(:workflow_action).permit(:name, :comment)
      end
  end
end
