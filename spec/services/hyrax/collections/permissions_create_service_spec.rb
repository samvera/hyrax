# frozen_string_literal: true
RSpec.describe Hyrax::Collections::PermissionsCreateService do
  let(:user) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }

  describe ".create_default" do
    let(:collection_type) { FactoryBot.create(:collection_type) }

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

    let(:collection) do
      FactoryBot.build(:collection_lw,
                       id: 'collection1',
                       collection_type: collection_type)
    end

    before do
      FactoryBot.create(:collection_type_participant, user_manage_attributes)
      FactoryBot.create(:collection_type_participant, group_manage_attributes)
    end

    it "creates the default permission template for the collection" do
      described_class.create_default(collection: collection, creating_user: user)

      expect(Hyrax::PermissionTemplate.find_by_source_id(collection.id)).to be_persisted
    end

    it "creates the default permission template access entries for the collection" do
      described_class.create_default(collection: collection, creating_user: user)

      expect(Hyrax::PermissionTemplate.find_by_source_id(collection.id).access_grants.count).to eq 4
    end
  end

  describe ".add_access" do
    let(:collection) { FactoryBot.create(:collection_lw, with_permission_template: true) }

    let(:grants) do
      [{ agent_type: Hyrax::PermissionTemplateAccess::GROUP,
         agent_id: 'archivist',
         access: Hyrax::PermissionTemplateAccess::DEPOSIT }]
    end

    it 'gives deposit access to archivist group' do
      described_class.add_access(collection_id: collection.id, grants: grants)

      expect(collection.permission_template.access_grants.deposit.map(&:agent_id))
        .to include 'archivist'
    end
  end
end
