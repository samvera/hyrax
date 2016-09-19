module Sipity
  RSpec.describe Strategy, type: :model do
    subject { described_class }
    its(:column_names) { is_expected.to include('name') }

    context '#initial_strategy_state' do
      subject { described_class.new(name: 'ETD Workflow') }
      it 'will create a state if one does not exist' do
        subject.save!
        expect { subject.initial_strategy_state }
          .to change { subject.strategy_states.count }.by(1)
      end
    end
  end
end
