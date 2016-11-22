module Sipity
  # A proxy for the entity that is being processed.
  # By using a proxy, we need not worry about polluting the proxy's concerns
  # with things related to processing.
  #
  # The goal is to keep this behavior separate, so that we can possibly
  # extract the information.
  class Entity < ActiveRecord::Base
    self.table_name = 'sipity_entities'

    belongs_to :workflow, class_name: 'Sipity::Workflow'
    belongs_to :workflow_state, class_name: 'Sipity::WorkflowState'

    has_many :entity_specific_responsibilities, dependent: :destroy, class_name: 'Sipity::EntitySpecificResponsibility'

    has_many :comments,
             foreign_key: :entity_id,
             dependent: :destroy,
             class_name: 'Sipity::Comment'

    def workflow_state_name
      workflow_state.name if workflow_state
    end

    # Defines the method #workflow_name
    delegate :name, to: :workflow, prefix: :workflow

    def proxy_for
      @proxy_for ||= GlobalID::Locator.locate(proxy_for_global_id)
    end
  end
end
