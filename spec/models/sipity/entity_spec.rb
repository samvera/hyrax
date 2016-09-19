module Sipity
  RSpec.describe Entity, type: :model do
    subject { described_class }
    its(:column_names) { is_expected.to include("proxy_for_id") }
    its(:column_names) { is_expected.to include("proxy_for_type") }
    its(:column_names) { is_expected.to include("strategy_id") }
    its(:column_names) { is_expected.to include("strategy_state_id") }

    context 'an instance' do
      subject { described_class.new }
      it { is_expected.to delegate_method(:strategy_state_name).to(:strategy_state).as(:name) }
      it { is_expected.to delegate_method(:strategy_name).to(:strategy).as(:name) }
    end
  end
end
