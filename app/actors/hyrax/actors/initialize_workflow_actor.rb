# frozen_string_literal: true
module Hyrax
  module Actors
    ##
    # @deprecated
    #
    # Responsible for generating the workflow for the given curation_concern.
    # Done through direct collaboration with the configured Hyrax::Actors::InitializeWorkflowActor.workflow_factory
    #
    # @see Hyrax::Actors::InitializeWorkflowActor.workflow_factory
    # @see Hyrax::Workflow::WorkflowFactory for default workflow factory
    class InitializeWorkflowActor < AbstractActor
      class_attribute :workflow_factory
      self.workflow_factory = ::Hyrax::Workflow::WorkflowFactory

      # @param [Hyrax::Actors::Environment] env
      # @return [Boolean] true if create was successful
      def create(env)
        Deprecation.warn('Use Hyrax::Listeners::WorkflowListener instead. ' \
          'Scheduled to be removed by 4.0.')
        next_actor.create(env) && create_workflow(env)
      end

      private

      # @return [TrueClass]
      def create_workflow(env)
        # if the entity exists, this is already initialized
        Sipity::Entity(env.curation_concern)
        true
      rescue Sipity::ConversionError
        workflow_factory.create(env.curation_concern, env.attributes, env.user)
      end
    end
  end
end
