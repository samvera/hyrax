# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for object lifecycle events that require workflow changes and
    # manages workflow accordingly.
    class WorkflowListener
      ##
      # @note respects class attribute configuration at
      #   {Hyrax::Actors::InitializeWorkflowActor.workflow_factory}, but falls
      #   back on {Hyrax::Workflow::WorkflowFactory} to prepare for removal of
      #   Actors
      # @return [#create] default: {Hyrax::Workflow::WorkflowFactory}
      def factory
        if defined?(Hyrax::Actors::InitializeWorkflowActor)
          Hyrax::Actors::InitializeWorkflowActor.workflow_factory
        else
          Hyrax::Workflow::WorkflowFactory
        end
      end

      ##
      # Called when 'object.deposited' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_deposited(event)
        return Rails.logger.warn("Skipping workflow initialization for #{event[:object]}; no user is given\n\t#{event}") if
          event[:user].blank?

        factory.create(event[:object], {}, event[:user])
      rescue Sipity::StateError, Sipity::ConversionError => err
        # don't error on known sipity error types; log instead
        Rails.logger.error(err)
      end
    end
  end
end
