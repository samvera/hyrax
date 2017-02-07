module Sipity
  RSpec.describe Workflow, type: :model, no_clean: true do
    context 'class configuration' do
      subject { described_class }
      its(:column_names) { is_expected.to include('name') }
    end

    subject { described_class.new(name: 'ETD Workflow') }
    it { is_expected.to belong_to(:permission_template) }

    context '#initial_workflow_state' do
      it 'will create a state if one does not exist' do
        subject.save!
        expect { subject.initial_workflow_state }
          .to change { subject.workflow_states.count }.by(1)
      end
    end
  end
end
