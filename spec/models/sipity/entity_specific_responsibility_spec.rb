module Sipity
  RSpec.describe EntitySpecificResponsibility, type: :model do
    subject { described_class }

    its(:column_names) { is_expected.to include('workflow_role_id') }
    its(:column_names) { is_expected.to include('entity_id') }
    its(:column_names) { is_expected.to include('agent_id') }
  end
end
