module Sipity
  # Throughout the workflow process, a processed entity may have numerous
  # states.
  class StrategyState < ActiveRecord::Base
    self.table_name = 'sipity_strategy_states'

    belongs_to :strategy
    has_many :originating_strategy_state_actions,
             dependent: :destroy,
             class_name: 'StrategyStateAction',
             foreign_key: :originating_strategy_state_id

    has_many :resulting_strategy_actions,
             dependent: :destroy,
             class_name: 'StrategyAction',
             foreign_key: :resulting_strategy_state_id

    has_many :comments,
             foreign_key: :originating_strategy_state_id,
             dependent: :destroy,
             class_name: 'Sipity::Comment'

    has_many :entities # TODO: should this be destroyed

    has_many :notifiable_contexts,
             dependent: :destroy,
             as: :scope_for_notification,
             class_name: 'Sipity::NotifiableContext'
  end
end
