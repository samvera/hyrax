module Sipity
  RSpec.describe StrategyState, type: :model do
    subject { described_class }
    its(:column_names) { is_expected.to include("strategy_id") }
    its(:column_names) { is_expected.to include("name") }
  end
end
