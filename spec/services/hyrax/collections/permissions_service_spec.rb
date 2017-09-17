RSpec.describe Hyrax::Collections::PermissionsService do
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

  describe ".can_deposit_in_collection" do
    subject { described_class.can_deposit_in_collection(collection: collection, user: user) }

    let(:permission_template) { create(:permission_template) }
    let(:collection) { create(:collection, user: user) }

    before do
      allow(Hyrax::PermissionTemplate).to receive(:find_by!).with(source_id: collection.id).and_return(permission_template)
    end

    it "exists" do
      expect(described_class).to respond_to(:can_deposit_in_collection)
    end

    it "returns true when user is a manager" do
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([user.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
      expect(subject).to be true
    end

    it "returns true when user is a depositor" do
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([user.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
      expect(subject).to be true
    end

    context "when manage group access defined" do
      before do
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return(['managers', 'more_managers'])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return([])
      end

      it "returns false if no user groups" do
        allow(user).to receive(:user_groups).and_return([])
        expect(subject).to be false
      end

      it "returns true if user has any valid group" do
        allow(user).to receive(:user_groups).and_return(['managers'])
        expect(subject).to be true
      end

      it "returns true if user has multiple valid groups" do
        allow(user).to receive(:user_groups).and_return(['more managers', 'managers', 'other_group'])
        expect(subject).to be true
      end
    end

    context "when deposit group access defined" do
      before do
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return([])
        allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return(['depositors', 'more_depositors'])
      end

      it "returns false if no user groups" do
        allow(user).to receive(:user_groups).and_return([])
        expect(subject).to be false
      end

      it "returns true if user has any valid group" do
        allow(user).to receive(:user_groups).and_return(['depositors'])
        expect(subject).to be true
      end

      it "returns true if user has multiple valid groups" do
        allow(user).to receive(:user_groups).and_return(['more depositors', 'depositors', 'other_group'])
        expect(subject).to be true
      end
    end

    it "returns false when user is neither a manager nor depositor" do
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'manage').and_return([user2.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'user', access: 'deposit').and_return([user2.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'manage').and_return(['managers', 'more_managers'])
      allow(permission_template).to receive(:agent_ids_for).with(agent_type: 'group', access: 'deposit').and_return(['depositors', 'more_depositors'])
      allow(user).to receive(:user_groups).and_return([])
      expect(subject).to be false
    end
  end
end
