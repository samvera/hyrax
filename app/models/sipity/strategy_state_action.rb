module Sipity
  # An actor can take the given action
  class StrategyStateAction < ActiveRecord::Base
    self.table_name = 'sipity_strategy_state_actions'
    belongs_to :originating_strategy_state, class_name: 'StrategyState'
    belongs_to :strategy_action
    has_many :strategy_state_action_permissions, dependent: :destroy
  end
end
