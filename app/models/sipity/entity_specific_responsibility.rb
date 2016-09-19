module Sipity
  # In what capacity can an actor act upon the given entity?
  class EntitySpecificResponsibility < ActiveRecord::Base
    self.table_name = 'sipity_entity_specific_responsibilities'
    belongs_to :entity
    belongs_to :strategy_role
    belongs_to :agent
  end
end
