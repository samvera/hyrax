module Sipity
  RSpec.describe StrategyStateAction, type: :model do
    subject { described_class }
    its(:column_names) { is_expected.to include("originating_strategy_state_id") }
    its(:column_names) { is_expected.to include("strategy_action_id") }
  end
end
