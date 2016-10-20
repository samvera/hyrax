require 'spec_helper'

describe CurationConcerns::Forms::WorkflowResponsibilityForm, :no_clean do
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
    let(:workflow) { instance_double(Sipity::Workflow, name: 'generic_work') }
    let(:role1) { instance_double(Sipity::Role, name: 'foo') }
    let(:role2) { instance_double(Sipity::Role, name: 'bar') }
    let(:wf_role1) { instance_double(Sipity::WorkflowRole, workflow: workflow, role: role1, id: 1) }
    let(:wf_role2) { instance_double(Sipity::WorkflowRole, workflow: workflow, role: role2, id: 2) }
    before do
      allow(Sipity::WorkflowRole).to receive(:all).and_return([wf_role1, wf_role2])
    end
    subject { instance.workflow_role_options }
    it { is_expected.to eq [['generic_work - foo', 1], ['generic_work - bar', 2]] }
  end
end
