module CurationConcerns
  module Publishable
    extend ActiveSupport::Concern

    included do
      # This holds the workflow state
      property :state, predicate: Vocab::FedoraResourceStatus.objState, multiple: false

      class_attribute :state_workflow, instance_writer: false
      self.state_workflow = StateWorkflow
    end

    # Override this method if you have some critera by which records should not
    # display in the search results.
    def suppressed?
      state_workflow.new(state).pending?
    end
  end
end
