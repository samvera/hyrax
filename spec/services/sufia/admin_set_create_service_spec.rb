require 'spec_helper'

RSpec.describe Sufia::AdminSetCreateService do
  let(:admin_set) { AdminSet.new(title: ['test']) }
  let(:workflow_name) { AdminSet::DEFAULT_WORKFLOW_NAME }
  let(:service) { described_class.new(admin_set, user, workflow_name) }
  let(:user) { create(:user) }

  describe "#create" do
    subject { service.create }

    context "when the admin_set is valid" do
      let(:permission_template) { Sufia::PermissionTemplate.find_by(admin_set_id: admin_set.id) }
      let(:grant) { permission_template.access_grants.first }
      it "creates an AdminSet, PermissionTemplate, and sets access" do
        expect do
          expect(subject).to be true
        end.to change { admin_set.persisted? }.from(false).to(true)
        expect(admin_set.read_groups).to eq ['public']
        expect(admin_set.edit_groups).to eq ['admin']
        expect(grant.agent_id).to eq user.user_key
        expect(grant.access).to eq 'manage'
        expect(admin_set.creator).to eq [user.user_key]
      end
    end

    context "when the admin_set is invalid" do
      let(:admin_set) { AdminSet.new } # Missing title
      it { is_expected.to be false }
    end
  end

  describe '.create_default!' do
    let(:default_admin_set_id) { AdminSet::DEFAULT_ID }
    let(:permission_template) { Sufia::PermissionTemplate.find_by!(admin_set_id: default_admin_set_id) }
    # It is important to test the side-effects as a default admin set is a fundamental assumption for Sufia >= 7.3
    it 'creates AdminSet, PermissionTemplate' do
      expect(AdminSet).not_to exist(default_admin_set_id)
      described_class.create_default!
      admin_set = AdminSet.find(default_admin_set_id)
      expect(admin_set).to be_persisted
      expect(permission_template).to be_persisted
      expect(permission_template.workflow_name).to eq workflow_name
    end
  end
end
