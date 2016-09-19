module Sipity
  RSpec.describe StrategyStateActionPermission, type: :model do
    subject { described_class }
    its(:column_names) { is_expected.to include("strategy_role_id") }
    its(:column_names) { is_expected.to include("strategy_state_action_id") }
  end
end
