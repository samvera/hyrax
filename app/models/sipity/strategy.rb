module Sipity
  # A named strategy for processing an entity. Originally I had thought of
  # calling this a Type, but once I extracted the Processing submodule,
  # type felt to much of a noun, not conveying potentiality. Strategy
  # conveys "things will happen" because of this.
  class Strategy < ActiveRecord::Base
    DEFAULT_INITIAL_STRATEGY_STATE = 'new'.freeze
    self.table_name = 'sipity_strategies'

    has_many :entities, dependent: :destroy
    has_many :strategy_states, dependent: :destroy
    has_many :strategy_actions, dependent: :destroy
    has_many :strategy_roles, dependent: :destroy

    def initial_strategy_state
      strategy_states.find_or_create_by!(name: DEFAULT_INITIAL_STRATEGY_STATE)
    end
  end
end
