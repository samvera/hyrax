require 'spec_helper'

RSpec.describe Hyrax::AdminSetCreateService do
  let(:user) { create(:user) }

  describe '.create_default_admin_set' do
    let(:admin_set) { AdminSet.find(AdminSet::DEFAULT_ID) }
    let(:responsibilities) { Sipity::WorkflowResponsibility.where(workflow_role: admin_set.active_workflow.workflow_roles) }
    # It is important to test the side-effects as a default admin set is a fundamental assumption for Hyrax.
    it 'creates AdminSet, Hyrax::PermissionTemplate, Sipity::Workflow(s), and activates a Workflow', slow: true do
      described_class.create_default_admin_set(admin_set_id: AdminSet::DEFAULT_ID, title: AdminSet::DEFAULT_TITLE)
      expect(admin_set.permission_template).to be_persisted
      expect(admin_set.active_workflow).to be_persisted
      expect(responsibilities.count).to eq 1
      expect(responsibilities.first.agent.proxy_for_id).to eq "registered"
      expect(responsibilities.first.agent.proxy_for_type).to eq "Hyrax::Group"
    end
  end

  describe ".call" do
    subject { described_class.call(admin_set: admin_set, creating_user: user) }

    let(:admin_set) { AdminSet.new(title: ['test']) }

    context "when using the default admin set" do
      let(:admin_set) { AdminSet.new(id: AdminSet::DEFAULT_ID) }

      it 'will raise ActiveFedora::IllegalOperation if you attempt to a default admin set' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    it "is a convenience method for .new#create" do
      service = instance_double(described_class)
      expect(described_class).to receive(:new).and_return(service)
      expect(service).to receive(:create)
      subject
    end
  end

  describe "an instance" do
    subject { service }

    let(:workflow_importer) { double(call: true) }
    let(:admin_set) { AdminSet.new(title: ['test']) }
    let(:service) { described_class.new(admin_set: admin_set, creating_user: user, workflow_importer: workflow_importer) }

    its(:default_workflow_importer) { is_expected.to respond_to(:call) }

    describe "#create" do
      subject { service.create }

      context "when the admin_set is valid" do
        let(:permission_template) { Hyrax::PermissionTemplate.find_by(admin_set_id: admin_set.id) }
        let(:grant) { permission_template.access_grants.first }
        let!(:role1) { Sipity::Role.create(name: 'testing') }
        let!(:role2) { Sipity::Role.create(name: 'breaking') }
        let!(:role3) { Sipity::Role.create(name: 'fixing') }
        let(:available_workflows) { [create(:workflow), create(:workflow)] }

        # rubocop:disable RSpec/AnyInstance
        before do
          allow_any_instance_of(Hyrax::PermissionTemplate).to receive(:available_workflows).and_return(available_workflows)
        end
        # rubocop:enable RSpec/AnyInstance

        it "creates an AdminSet, PermissionTemplate, Workflows, activates the default workflow, and sets access" do
          expect(Sipity::Workflow).to receive(:activate!).with(permission_template: kind_of(Hyrax::PermissionTemplate), workflow_name: Hyrax.config.default_active_workflow_name)
          expect do
            expect(subject).to be true
          end.to change { admin_set.persisted? }.from(false).to(true)
            .and change { Sipity::WorkflowResponsibility.count }.by(6)
          expect(admin_set.read_groups).to eq ['public']
          expect(admin_set.edit_groups).to eq ['admin']
          expect(grant.agent_id).to eq user.user_key
          expect(grant.access).to eq 'manage'
          expect(admin_set.creator).to eq [user.user_key]
          expect(workflow_importer).to have_received(:call).with(permission_template: permission_template)
          expect(permission_template).to be_persisted
        end
      end

      context "when the admin_set is invalid" do
        let(:admin_set) { AdminSet.new } # Missing title

        it { is_expected.to be false }
        it 'will not call the workflow_importer' do
          expect(workflow_importer).not_to have_received(:call)
        end
      end
    end
  end
end
