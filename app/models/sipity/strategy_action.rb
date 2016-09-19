module Sipity
  # A named thing that "happens" to a processing entity.
  class StrategyAction < ActiveRecord::Base
    self.table_name = 'sipity_strategy_actions'

    belongs_to :strategy
    belongs_to :resulting_strategy_state, class_name: 'Sipity::StrategyState'

    has_many :entity_action_registers, dependent: :destroy

    has_many :strategy_state_actions, dependent: :destroy

    has_many :notifiable_contexts,
             dependent: :destroy,
             as: :scope_for_notification,
             class_name: 'Sipity::NotifiableContext'

    has_many :comments,
             foreign_key: :originating_strategy_action_id,
             dependent: :destroy,
             class_name: 'Sipity::Comment'
  end
end
