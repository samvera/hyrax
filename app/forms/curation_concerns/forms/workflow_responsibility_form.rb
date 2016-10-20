module CurationConcerns
  module Forms
    class WorkflowResponsibilityForm
      def initialize(params = {})
        model_instance.workflow_role_id = params[:workflow_role_id]
        if params[:user_id]
          user = ::User.find(params[:user_id])
          model_instance.agent = user.to_sipity_agent
        end
      end

      def model_instance
        @model ||= Sipity::WorkflowResponsibility.new
      end

      def to_model
        model_instance
      end

      delegate :model_name, :to_key, :workflow_role_id, :persisted?, :save!, to: :model_instance

      def user_id
        nil
      end

      def user_options
        ::User.all
      end

      # The select options for choosing a responsibility
      def workflow_role_options
        Sipity::WorkflowRole.all.map { |wf_role| [label(wf_role), wf_role.id] }
      end

      private

        def label(wf_role)
          "#{wf_role.workflow.name} - #{wf_role.role.name}"
        end
    end
  end
end
