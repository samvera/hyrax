module Sipity
  RSpec.describe StrategyRole, type: :model do
    subject { described_class }
    its(:column_names) { is_expected.to include('strategy_id') }
    its(:column_names) { is_expected.to include('role_id') }
  end
end
