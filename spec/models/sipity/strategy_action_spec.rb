module Sipity
  RSpec.describe StrategyAction, type: :model do
    context 'database configuration' do
      subject { described_class }
      its(:column_names) { is_expected.to include('strategy_id') }
      its(:column_names) { is_expected.to include('resulting_strategy_state_id') }
      its(:column_names) { is_expected.to include('name') }
    end
  end
end
