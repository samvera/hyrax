describe Hyrax::Workflow::WorkflowByAdminSetStrategy, :no_clean do
  context "when using default workflow strategy" do
    let(:workflow_strategy) { described_class.new(nil, {}) }

    describe '#workflow_id' do
      subject { workflow_strategy.workflow_id }
      it { is_expected.to eq nil }
    end
  end

  context "when using a non-default workflow strategy" do
    let!(:admin_set) { AdminSet.create(title: ["test"]) }
    let!(:workflow) { Sipity::Workflow.create(name: "default", label: "default") }
    let!(:permission_template) { Hyrax::PermissionTemplate.create(workflow_id: workflow.id, admin_set_id: admin_set.id) }
    let(:workflow_strategy) { described_class.new(nil, admin_set_id: admin_set.id) }

    describe '#workflow_id' do
      subject { workflow_strategy.workflow_id }
      it { is_expected.to eq workflow.id }
    end
  end
end
