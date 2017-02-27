require 'spec_helper'

RSpec.describe Hyrax::AdminSetCreateService do
  let(:admin_set) { AdminSet.new(title: ['test']) }
  let(:workflow_importer) { double(call: true) }
  let(:service) { described_class.new(admin_set: admin_set, creating_user: user, workflow_importer: workflow_importer) }
  let(:user) { instance_double(User, user_key: 'user-1234') }

  subject { service }
  its(:default_workflow_importer) { is_expected.to respond_to(:call) }

  describe '.create_default_admin_set' do
    # It is important to test the side-effects as a default admin set is a fundamental assumption for Hyrax.
    it 'creates AdminSet, Hyrax::PermissionTemplate, Sipity::Workflow(s), and activates a Workflow', slow: true do
      described_class.create_default_admin_set(admin_set_id: AdminSet::DEFAULT_ID, title: AdminSet::DEFAULT_TITLE)
      admin_set = AdminSet.find(AdminSet::DEFAULT_ID)
      expect(admin_set.permission_template).to be_persisted
      expect(admin_set.active_workflow).to be_persisted
    end
  end

  describe ".call" do
    it 'will raise ActiveFedora::IllegalOperation if you attempt to a default admin set' do
      expect { described_class.call(admin_set: AdminSet.new(id: AdminSet::DEFAULT_ID), creating_user: user) }.to raise_error(RuntimeError)
    end

    it "is a convenience method for .new#create" do
      service = instance_double(described_class)
      expect(described_class).to receive(:new).and_return(service)
      expect(service).to receive(:create)
      described_class.call(admin_set: admin_set, creating_user: user)
    end
  end

  describe "#create" do
    subject { service.create }

    context "when the admin_set is valid" do
      let(:permission_template) { Hyrax::PermissionTemplate.find_by(admin_set_id: admin_set.id) }
      let(:grant) { permission_template.access_grants.first }
      it "is creates an AdminSet, PermissionTemplate, Workflows, activates the default workflow, and sets access" do
        expect(Sipity::Workflow).to receive(:activate!).with(permission_template: kind_of(Hyrax::PermissionTemplate), workflow_name: Hyrax.config.default_active_workflow_name)
        expect do
          expect(subject).to be true
        end.to change { admin_set.persisted? }.from(false).to(true)
        expect(admin_set.read_groups).to eq ['public']
        expect(admin_set.edit_groups).to eq ['admin']
        expect(grant.agent_id).to eq user.user_key
        expect(grant.access).to eq 'manage'
        expect(admin_set.creator).to eq [user.user_key]
        expect(workflow_importer).to have_received(:call).with(permission_template: permission_template)
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
