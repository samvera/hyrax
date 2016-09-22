module CurationConcerns
  class WorkflowActionsController < ApplicationController
    before_action :authenticate_user!

    def update
      work = ActiveFedora::Base.find(params[:id])
      workflow_form = CurationConcerns::Forms::WorkflowActionForm.new(current_ability: current_ability, work: work, params: form_params)
      if workflow_form.save
        redirect_to [main_app, work], notice: "The #{work.human_readable_type} has been updated."
      else
        render 'curation_concerns/base/unauthorized', status: :unauthorized
      end
    end

    def form_params
      params.require(:workflow_action).permit(:name, :comment)
    end
  end
end
