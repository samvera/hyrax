module Sipity
  RSpec.describe WorkflowStateAction, type: :model do
    subject { described_class }

    its(:column_names) { is_expected.to include("originating_workflow_state_id") }
    its(:column_names) { is_expected.to include("workflow_action_id") }
  end
end
