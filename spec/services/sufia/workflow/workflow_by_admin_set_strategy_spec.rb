describe Sufia::Workflow::WorkflowByAdminSetStrategy, :no_clean do
  context "when using default workflow strategy" do
    let(:workflowstrategy) { described_class.new(nil, {}) }

    describe "workflow_name" do
      subject { workflowstrategy.workflow_name }
      it { is_expected.to eq 'default' }
    end
  end

  context "whatn using a non-default workflow strategy" do
    let!(:admin_set) { AdminSet.create(title: ["test"]) }
    let!(:permission_template) { Sufia::PermissionTemplate.create(workflow_name: "test", admin_set_id: admin_set.id) }
    let(:workflowstrategy) { described_class.new(nil, admin_set_id: admin_set.id) }

    describe "workflow_name" do
      subject { workflowstrategy.workflow_name }
      it { is_expected.to eq permission_template.workflow_name }
    end
  end
end
