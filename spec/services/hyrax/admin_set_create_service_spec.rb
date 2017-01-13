require 'spec_helper'

RSpec.describe Hyrax::AdminSetCreateService do
  let(:admin_set) { AdminSet.new(title: ['test']) }
  let(:service) { described_class.new(admin_set, user) }
  let(:user) { create(:user) }

  describe ".call" do
    it "is a convenience method for .new#create" do
      service = instance_double(described_class)
      expect(described_class).to receive(:new).and_return(service)
      expect(service).to receive(:create)
      described_class.call(admin_set, user)
    end
  end

  describe "#create" do
    subject { service.create }

    context "when the admin_set is valid" do
      let(:permission_template) { Hyrax::PermissionTemplate.find_by(admin_set_id: admin_set.id) }
      let(:grant) { permission_template.access_grants.first }
      it "is creates an AdminSet, PermissionTemplate and sets access" do
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
end
