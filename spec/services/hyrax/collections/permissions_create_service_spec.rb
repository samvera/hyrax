# frozen_string_literal: true
RSpec.describe Hyrax::Collections::PermissionsCreateService do
  let(:user) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:query_service) { Hyrax.query_service }

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

    before do
      FactoryBot.create(:collection_type_participant, user_manage_attributes)
      FactoryBot.create(:collection_type_participant, group_manage_attributes)
    end

    context "for collection" do
      let(:collection) do
        FactoryBot.valkyrie_create(:hyrax_collection,
                                   collection_type_gid: collection_type.to_global_id,
                                   with_permission_template: false)
      end

      it "creates the default permission template and access entries" do
        expect { described_class.create_default(collection: collection, creating_user: user) }
          .to change { Hyrax::PermissionTemplate.count }
          .by(1)
          .and change { Hyrax::PermissionTemplateAccess.count }
          .by(4)
      end
    end

    context "for administrative set" do
      let(:collection_type) { FactoryBot.create(:admin_set_collection_type) }
      let(:admin_set) do
        FactoryBot.valkyrie_create(:hyrax_admin_set,
                                   with_permission_template: false)
      end

      it "creates the default permission template and access entries" do
        expect { described_class.create_default(collection: admin_set, creating_user: user) }
          .to change { Hyrax::PermissionTemplate.count }
          .by(1)
          .and change { Hyrax::PermissionTemplateAccess.count }
          .by(4)
      end
    end
  end

  describe ".add_access" do
    let(:grants) do
      [
        {
          agent_type: Hyrax::PermissionTemplateAccess::GROUP,
          agent_id: 'archivist',
          access: Hyrax::PermissionTemplateAccess::DEPOSIT
        }
      ]
    end

    context "for collection" do
      let!(:collection) do
        FactoryBot.valkyrie_create(:hyrax_collection,
                                   with_permission_template: true)
      end

      it 'gives deposit access to archivist group' do
        expect { described_class.add_access(collection_id: collection.id, grants: grants) }
          .to change { Hyrax::PermissionTemplate.count }
          .by(0)
          .and change { Hyrax::PermissionTemplateAccess.count }
          .by(1)

        # collection depositors are granted read access to the collection
        pulled_collection = query_service.find_by(id: collection.id)
        expect(pulled_collection.permission_manager.read_groups.to_a)
          .to include 'archivist'
      end
    end

    context "for administrative set" do
      let!(:admin_set) do
        FactoryBot.valkyrie_create(:hyrax_admin_set,
                                   with_permission_template: true)
      end

      it 'gives deposit access to archivist group' do
        expect { described_class.add_access(collection_id: admin_set.id, grants: grants) }
          .to change { Hyrax::PermissionTemplate.count }
          .by(0)
          .and change { Hyrax::PermissionTemplateAccess.count }
          .by(1)

        # collection depositors are granted read access to the collection
        pulled_admin_set = query_service.find_by(id: admin_set.id)
        expect(pulled_admin_set.permission_manager.read_groups.to_a)
          .to include 'archivist'
      end
    end
  end
end
