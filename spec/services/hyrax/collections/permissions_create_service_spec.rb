RSpec.describe Hyrax::Collections::PermissionsCreateService do
  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  describe ".create_default" do
    subject { described_class.create_default(collection: collection, creating_user: user) }

    let(:collection_type) { create(:collection_type) }
    let(:user_manage_attributes) do
      {
        hyrax_collection_type_id: collection_type.id,
        access: 'manage',
        agent_id: user2.user_key,
        agent_type: 'user'
      }
    end
    let(:group_manage_attributes) do
      {
        hyrax_collection_type_id: collection_type.id,
        access: 'manage',
        agent_id: 'manage_group',
        agent_type: 'group'
      }
    end
    let!(:collection_type_participant) { create(:collection_type_participant, user_manage_attributes) }
    let!(:collection_type_participant2) { create(:collection_type_participant, group_manage_attributes) }
    let(:collection) { create(:collection, collection_type_gid: collection_type.gid) }

    before do
      subject
    end

    it "creates the default permission template for the collection" do
      expect(Hyrax::PermissionTemplate.find_by_source_id(collection.id)).to be_persisted
    end

    it "creates the default permission template access entries for the collection" do
      expect(Hyrax::PermissionTemplate.find_by_source_id(collection.id).access_grants.count).to eq 4
    end
  end
end
