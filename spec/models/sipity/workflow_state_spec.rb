module Sipity
  RSpec.describe WorkflowState, type: :model do
    subject { described_class }

    its(:column_names) { is_expected.to include("workflow_id") }
    its(:column_names) { is_expected.to include("name") }

    describe "#entities" do
      let(:workflow_state) { create(:workflow_state, name: 'test') }
      let!(:entity)        { Sipity::Entity.create!(workflow_state: workflow_state, proxy_for_global_id: "abc123", workflow_id: workflow_state.workflow_id) }

      it "has entites" do
        expect(workflow_state.entities).to match_array([entity])
      end
    end
  end
end
