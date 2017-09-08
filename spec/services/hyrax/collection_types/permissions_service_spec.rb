RSpec.describe Hyrax::CollectionTypes::PermissionsService do
  let(:user1) { create(:user, groups: 'create_group') }
  let(:user2) { create(:user, groups: 'manage_group') }
  let(:user3) { create(:user) }
  let(:user4) { create(:user, groups: 'admin') }
  let(:collection_type_1) { create(:collection_type) }
  let(:collection_type_2) { create(:collection_type) }
  let(:collection_type_3) { create(:collection_type) }

  let(:user_create_attributes) do
    {
      hyrax_collection_type_id: collection_type_1.id,
      access: 'create',
      agent_id: user1.user_key,
      agent_type: 'user'
    }
  end
  let(:group_create_attributes) do
    {
      hyrax_collection_type_id: collection_type_2.id,
      access: 'create',
      agent_id: 'create_group',
      agent_type: 'group'
    }
  end
  let(:user_manage_attributes) do
    {
      hyrax_collection_type_id: collection_type_1.id,
      access: 'manage',
      agent_id: user2.user_key,
      agent_type: 'user'
    }
  end
  let(:group_manage_attributes) do
    {
      hyrax_collection_type_id: collection_type_3.id,
      access: 'manage',
      agent_id: 'manage_group',
      agent_type: 'group'
    }
  end
  let!(:collection_type_participant1) { create(:collection_type_participant, user_create_attributes) }
  let!(:collection_type_participant2) { create(:collection_type_participant, group_create_attributes) }
  let!(:collection_type_participant3) { create(:collection_type_participant, user_manage_attributes) }
  let!(:collection_type_participant4) { create(:collection_type_participant, group_manage_attributes) }

  describe '.collection_type_for_user search results' do
    subject { described_class.collection_types_for_user(user: user, roles: access) }

    context 'users with create access' do
      let(:user) { user1 }
      let(:access) { 'create' }

      it "returns two collection types" do
        expect(subject.map(&:id)).to match_array [collection_type_1.id, collection_type_2.id]
      end
    end

    context 'users with manage access' do
      let(:user) { user2 }
      let(:access) { 'manage' }

      it "returns two collection types" do
        expect(subject.map(&:id)).to match_array [collection_type_1.id, collection_type_3.id]
      end
    end

    context 'users with no access' do
      let(:user) { user3 }
      let(:access) { ['manage', 'create'] }

      it "returns no collection types" do
        expect(subject.map(&:id)).to match_array []
      end
    end

    context 'admin users' do
      let(:user) { user4 }
      let(:access) { ['manage', 'create'] }

      it "returns all collection types" do
        expect(subject.map(&:id)).to match_array [collection_type_1.id, collection_type_2.id, collection_type_3.id]
      end
    end

    describe '.can_create_collection_types results' do
      subject { described_class.can_create_collection_types(user: user) }

      context 'user with create access' do
        let(:user) { user1 }

        it "finds two collection types" do
          expect(subject.map(&:id)).to match_array [collection_type_1.id, collection_type_2.id]
        end
      end

      context 'admin users' do
        let(:user) { user4 }

        it "returns all collection types" do
          expect(subject.map(&:id)).to match_array [collection_type_1.id, collection_type_2.id, collection_type_3.id]
        end
      end

      context 'users with no access' do
        let(:user) { user3 }

        it "returns no collection types" do
          expect(subject.map(&:id)).to match_array []
        end
      end

      context 'users with manage access' do
        let(:user) { user2 }

        it "returns two collection types" do
          expect(subject.map(&:id)).to match_array [collection_type_1.id, collection_type_3.id]
        end
      end

      context 'users with both manage and create access' do
        let(:user5) { create(:user, groups: 'manage_group') }
        let(:user) { user5 }
        let(:collection_type_4) { create(:collection_type) }
        let(:user5_user_create_attributes) do
          {
            hyrax_collection_type_id: collection_type_1.id,
            access: 'create',
            agent_id: user5.user_key,
            agent_type: 'user'
          }
        end
        let(:user5_group_manage_attributes) do
          {
            hyrax_collection_type_id: collection_type_3.id,
            access: 'manage',
            agent_id: 'manage_group',
            agent_type: 'group'
          }
        end
        let!(:collection_type_participant5) { create(:collection_type_participant, user5_user_create_attributes) }
        let!(:collection_type_participant6) { create(:collection_type_participant, user5_group_manage_attributes) }

        it "returns two collection types" do
          expect(subject.map(&:id)).to match_array [collection_type_1.id, collection_type_3.id]
        end
      end
    end
  end
end
