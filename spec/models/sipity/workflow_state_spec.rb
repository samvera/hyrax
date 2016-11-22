module Sipity
  RSpec.describe WorkflowState, type: :model, no_clean: true do
    subject { described_class }
    its(:column_names) { is_expected.to include("workflow_id") }
    its(:column_names) { is_expected.to include("name") }
  end
end
