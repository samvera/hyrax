module Hyrax
  # Workflow considerations
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

    def to_sipity_entity
      raise "Can't create an entity until the model has been persisted" unless persisted?
      @sipity_entity ||= Sipity::Entity.find_by(proxy_for_global_id: to_global_id.to_s)
    end
  end
end
