module Sipity
  # The intersection of an Actor and a Role. In other words, the actor
  # is paid to do things; What do those things represent.
  #
  # @see Sipity::Role for discussion of roles
  class StrategyResponsibility < ActiveRecord::Base
    self.table_name = 'sipity_strategy_responsibilities'
    belongs_to :agent
    belongs_to :strategy_role
  end
end
