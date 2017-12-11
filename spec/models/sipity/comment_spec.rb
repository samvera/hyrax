module Sipity
  RSpec.describe Comment, type: :model do
    context 'database configuration' do
      subject { described_class }

      its(:column_names) { is_expected.to include('entity_id') }
      its(:column_names) { is_expected.to include('agent_id') }
      its(:column_names) { is_expected.to include('comment') }
    end

    describe '#name_of_commentor' do
      let(:instance) { described_class.new }
      let(:agent) { instance_double(Agent, proxy_for: user) }
      let(:user) { instance_double(User, to_s: 'Hiya') }

      subject { instance.name_of_commentor }

      before do
        allow(instance).to receive(:agent).and_return(agent)
      end
      it { is_expected.to eq('Hiya') }
    end
  end
end
