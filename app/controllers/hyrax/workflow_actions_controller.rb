module Hyrax
  class WorkflowActionsController < ApplicationController
    before_action :authenticate_user!

    def update
      @curation_concern = ActiveFedora::Base.find(params[:id])
      workflow_action_form = Hyrax::Forms::WorkflowActionForm.new(
        current_ability: current_ability,
        work: @curation_concern,
        attributes: workflow_action_params
      )
      if workflow_action_form.save
        after_update_response
      else
        respond_to do |wants|
          wants.html { render 'hyrax/base/unauthorized', status: :unauthorized }
          wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: @curation_concern.errors }) }
        end
      end
    end

    private

      def workflow_action_params
        params.require(:workflow_action).permit(:name, :comment)
      end

      def after_update_response
        respond_to do |wants|
          wants.html { redirect_to [main_app, @curation_concern], notice: "The #{@curation_concern.human_readable_type} has been updated." }
          wants.json { render 'hyrax/base/show', status: :ok, location: polymorphic_path([main_app, @curation_concern]) }
        end
      end
  end
end
