module Hyrax
  class WorkflowActionsController < ApplicationController
    before_action :authenticate_user!

    def update
      if workflow_action_form.save
        after_update_response
      else
        respond_to do |wants|
          wants.html { render 'hyrax/base/unauthorized', status: :unauthorized }
          wants.json { render_json_response(response_type: :unprocessable_entity, options: { errors: 'unable to update workflow' }) }
        end
      end
    end

    private

      def resource
        @resource ||= find_resource(params[:id])
      end

      def workflow_action_form
        @workflow_action_form ||= Hyrax::Forms::WorkflowActionForm.new(
          current_ability: current_ability,
          work: resource,
          attributes: workflow_action_params
        )
      end

      def workflow_action_params
        params.require(:workflow_action).permit(:name, :comment)
      end

      def after_update_response
        respond_to do |wants|
          wants.html { redirect_to [main_app, resource], notice: "The #{resource.human_readable_type} has been updated." }
          wants.json { render 'hyrax/base/show', status: :ok, location: polymorphic_path([main_app, resource]) }
        end
      end

      def find_resource(id)
        Hyrax::Queries.find_by(id: Valkyrie::ID.new(id))
      end
  end
end
