# frozen_string_literal: true

module Hyrax
  module Workflow
    ##
    # Decorates objects with attributes with their workflow state.
    class ObjectInWorkflowDecorator < Draper::Decorator
      delegate_all

      ##
      # @!attribute [w] workflow
      #   @return [Sipity::Workflow]
      # @!attribute [w] workflow_state
      #   @return [Sipity::WorkflowState]
      attr_writer :workflow, :workflow_state

      ##
      # @return [Boolean]
      def published?
        Hyrax::Admin::WorkflowsController.deposited_workflow_state_name ==
          workflow_state
      end

      ##
      # @return [String]
      def workflow_state
        @workflow_state&.name || 'unknown'
      end
    end
  end
end
