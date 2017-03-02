module Hyrax
  module Actors
    # Responsible for generating the workflow for the given curation_concern.
    # Done through direct collaboration with the configured Hyrax::Actors::InitializeWorkflowActor.workflow_factory
    #
    # @see Hyrax::Actors::InitializeWorkflowActor.workflow_factory
    # @see Hyrax::Workflow::WorkflowFactory for default workflow factory
    class InitializeWorkflowActor < AbstractActor
      class_attribute :workflow_factory
      self.workflow_factory = ::Hyrax::Workflow::WorkflowFactory

      def create(attributes)
        next_actor.create(attributes) && create_workflow(attributes)
      end

      private

        # @return [TrueClass]
        def create_workflow(attributes)
          workflow_factory.create(curation_concern, attributes, user)
        end
    end
  end
end
