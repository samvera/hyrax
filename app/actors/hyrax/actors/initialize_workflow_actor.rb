module Hyrax
  module Actors
    class InitializeWorkflowActor < AbstractActor
      class_attribute :workflow_factory
      self.workflow_factory = ::Hyrax::Workflow::WorkflowFactory

      def create(attributes)
        next_actor.create(attributes) && create_workflow(attributes)
      end

      private

        # @return [TrueClass]
        def create_workflow(attributes)
          workflow_factory.create(curation_concern, attributes, ability.current_user)
        end
    end
  end
end
