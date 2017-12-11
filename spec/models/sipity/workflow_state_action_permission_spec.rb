module Sipity
  RSpec.describe WorkflowStateActionPermission, type: :model do
    subject { described_class }

    its(:column_names) { is_expected.to include("workflow_role_id") }
    its(:column_names) { is_expected.to include("workflow_state_action_id") }
  end
end
