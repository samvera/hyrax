module CurationConcerns
  module Publishable
    extend ActiveSupport::Concern

    included do
      # This holds the workflow state
      property :state, predicate: Vocab::FedoraResourceStatus.objState, multiple: false

      class_attribute :state_workflow, instance_writer: false
      self.state_workflow = StateWorkflow
    end

    # This method has been overriden to handle mediated deposit
    def suppressed?
      state_workflow.new(state).pending? || state_workflow.new(state).state == ::RDF::URI('http://fedora.info/definitions/1/0/access/ObjState#inactive')
    end
  end
end
