module Sipity
  # Who can trigger this event?
  class StrategyStateActionPermission < ActiveRecord::Base
    self.table_name = 'sipity_strategy_state_action_permissions'
    belongs_to :strategy_role
    belongs_to :strategy_state_action
  end
end
