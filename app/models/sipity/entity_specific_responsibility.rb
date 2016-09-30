module Sipity
  # In what capacity can an agent act upon the given entity?
  class EntitySpecificResponsibility < ActiveRecord::Base
    self.table_name = 'sipity_entity_specific_responsibilities'
    belongs_to :entity, class_name: 'Sipity::Entity'
    belongs_to :workflow_role, class_name: 'Sipity::WorkflowRole'
    belongs_to :agent, class_name: 'Sipity::Agent'
  end
end
