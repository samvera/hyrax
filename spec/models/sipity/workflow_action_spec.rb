module Sipity
  RSpec.describe WorkflowAction, type: :model do
    context 'database configuration' do
      subject { described_class }

      its(:column_names) { is_expected.to include('workflow_id') }
      its(:column_names) { is_expected.to include('resulting_workflow_state_id') }
      its(:column_names) { is_expected.to include('name') }
    end
  end
end
