module Sipity
  RSpec.describe WorkflowRole, type: :model, no_clean: true do
    subject { described_class }
    its(:column_names) { is_expected.to include('workflow_id') }
    its(:column_names) { is_expected.to include('role_id') }

    describe '#label' do
      let(:role) { Sipity::Role[:depositor] }
      let(:workflow) { create(:workflow) }
      let(:workflow_role) { described_class.new(role: role, workflow: workflow) }
      subject { workflow_role.label }
      it { is_expected.to be_a(String) }
    end
  end
end
