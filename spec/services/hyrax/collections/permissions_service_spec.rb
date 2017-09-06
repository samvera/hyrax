RSpec.describe Hyrax::Collections::PermissionsService do
  describe "create_default" do
    subject { described_class.create_default(collection: collection, creating_user: user) }

    let(:user) { create(:user) }
    let(:user2) { create(:user) }
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

  describe "user_edit_grants_for_collection" do
    it "exists" do
      expect(described_class).to respond_to(:user_edit_grants_for_collection)
    end
  end

  describe "can_deposit_in_collection" do
    it "exists" do
      expect(described_class).to respond_to(:can_deposit_in_collection)
    end
  end

  describe "user_view_grants_for_collection" do
    it "exists" do
      expect(described_class).to respond_to(:user_view_grants_for_collection)
    end
  end

  describe "group_edit_grants_for_collection" do
    it "exists" do
      expect(described_class).to respond_to(:group_edit_grants_for_collection)
    end
  end

  describe "group_deposit_grants_for_collection" do
    it "exists" do
      expect(described_class).to respond_to(:group_deposit_grants_for_collection)
    end
  end

  describe "group_view_grants_for_collection" do
    it "exists" do
      expect(described_class).to respond_to(:group_view_grants_for_collection)
    end
  end
end
