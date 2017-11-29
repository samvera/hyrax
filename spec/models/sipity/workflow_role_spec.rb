module Sipity
  RSpec.describe WorkflowRole, type: :model do
    subject { described_class }

    its(:column_names) { is_expected.to include('workflow_id') }
    its(:column_names) { is_expected.to include('role_id') }
  end
end
