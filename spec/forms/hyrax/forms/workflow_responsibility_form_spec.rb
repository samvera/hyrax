# frozen_string_literal: true
RSpec.describe Hyrax::Forms::WorkflowResponsibilityForm do
  let(:instance) { described_class.new }

  describe "#initialize" do
    let(:user) { create(:user) }
    let(:instance) { described_class.new(user_id: user.id, workflow_role_id: 7) }

    subject { instance.model_instance }

    it "creates an agent and sets the workflow_role_id" do
      expect(subject.agent).to be_kind_of Sipity::Agent
      expect(subject.workflow_role_id).to eq 7
    end
  end

  describe "#user_options" do
    subject { instance.user_options }

    it { is_expected.to eq User.all }
  end

  describe "#workflow_role_options" do
    subject { instance.workflow_role_options }

    let(:wf_role1) { instance_double(Sipity::WorkflowRole, id: 1) }
    let(:wf_role2) { instance_double(Sipity::WorkflowRole, id: 2) }

    before do
      allow(Sipity::WorkflowRole).to receive(:all).and_return([wf_role1, wf_role2])
      allow(Hyrax::Admin::WorkflowRolePresenter).to receive(:new)
        .with(wf_role1)
        .and_return(instance_double(Hyrax::Admin::WorkflowRolePresenter,
                                    label: 'generic_work - foo'))
      allow(Hyrax::Admin::WorkflowRolePresenter).to receive(:new)
        .with(wf_role2)
        .and_return(instance_double(Hyrax::Admin::WorkflowRolePresenter,
                                    label: 'generic_work - bar'))
    end
    it { is_expected.to eq [['generic_work - bar', 2], ['generic_work - foo', 1]] }
  end
end
