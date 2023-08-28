# frozen_string_literal: true
RSpec.describe Hyrax::EditPermissionsService do
  let(:my_user) { FactoryBot.create(:user) }
  let(:ability) { Ability.new(my_user) }
  # build users for testing
  let(:mgr1) { FactoryBot.create(:user) }
  let(:mgr2) { FactoryBot.create(:user) }
  let(:mgr3) { FactoryBot.create(:user) }
  let(:mgr4) { FactoryBot.create(:user) }
  let(:mgr5) { FactoryBot.create(:user) }
  let(:vw1) { FactoryBot.create(:user) }
  let(:vw2) { FactoryBot.create(:user) }
  let(:vw3) { FactoryBot.create(:user) }
  let(:vw4) { FactoryBot.create(:user) }
  let(:coll_creator) { FactoryBot.create(:user) }

  # build collections for testing
  # my_user has no manage rights to admin_set
  let(:admin_set) do
    FactoryBot.valkyrie_create(:hyrax_admin_set,
                               :with_permission_template,
                               user: coll_creator,
                               access_grants: [{ access: Hyrax::PermissionTemplateAccess::MANAGE,
                                                 agent_id: mgr1.user_key,
                                                 agent_type: Hyrax::PermissionTemplateAccess::USER },
                                               { access: Hyrax::PermissionTemplateAccess::VIEW,
                                                 agent_id: vw1.user_key,
                                                 agent_type: Hyrax::PermissionTemplateAccess::USER }])
  end

  let(:sharable_type) { FactoryBot.create(:collection_type, :sharable) }
  let(:nonsharable_type) { FactoryBot.create(:collection_type, :not_sharable) }

  # my_user has manage rights to this collection
  let(:sharable_coll1) do
    FactoryBot.valkyrie_create(:hyrax_collection,
                               user: coll_creator,
                               collection_type_gid: sharable_type.to_global_id.to_s,
                               access_grants: [{ access: Hyrax::PermissionTemplateAccess::MANAGE,
                                                 agent_id: mgr2.user_key,
                                                 agent_type: Hyrax::PermissionTemplateAccess::USER },
                                               { access: Hyrax::PermissionTemplateAccess::MANAGE,
                                                 agent_id: my_user.user_key,
                                                 agent_type: Hyrax::PermissionTemplateAccess::USER },
                                               { access: Hyrax::PermissionTemplateAccess::VIEW,
                                                 agent_id: vw2.user_key,
                                                 agent_type: Hyrax::PermissionTemplateAccess::USER }])
  end

  # my_user has no manage rights to this collection
  let(:sharable_coll2) do
    FactoryBot.valkyrie_create(:hyrax_collection,
                               user: coll_creator,
                               collection_type_gid: sharable_type.to_global_id.to_s,
                               access_grants: [{ access: Hyrax::PermissionTemplateAccess::MANAGE,
                                                 agent_id: mgr3.user_key,
                                                 agent_type: Hyrax::PermissionTemplateAccess::USER },
                                               { access: Hyrax::PermissionTemplateAccess::VIEW,
                                                 agent_id: vw3.user_key,
                                                 agent_type: Hyrax::PermissionTemplateAccess::USER }])
  end

  # non-sharable collections do not impact the permissions of the works
  let(:nonsharable_collection) do
    FactoryBot.valkyrie_create(:hyrax_collection,
                               user: coll_creator,
                               collection_type_gid: nonsharable_type.to_global_id.to_s,
                               access_grants: [{ access: Hyrax::PermissionTemplateAccess::MANAGE,
                                                 agent_id: mgr4.user_key,
                                                 agent_type: Hyrax::PermissionTemplateAccess::USER },
                                               { access: Hyrax::PermissionTemplateAccess::VIEW,
                                                 agent_id: vw4.user_key,
                                                 agent_type: Hyrax::PermissionTemplateAccess::USER }])
  end

  # @note: We are using multiple collections only in order to test the complex situations
  # all at once. Collection permissions are explicitly added onto the work here because
  # multi-membership at the time of creation prevents sharing of permissions to the work.
  # However, since we don't know which work's permissions were actually inherited from a
  # sharable collection, we have to assume they all need to be restricted.
  # build work for testing:
  let(:work) do
    FactoryBot.valkyrie_create(:hyrax_work,
                               depositor: my_user.user_key,
                               edit_users: [mgr2, mgr3, mgr4, mgr5],
                               read_users: [vw2, vw3, vw4],
                               visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
                               member_of_collection_ids: [sharable_coll1.id, sharable_coll2.id, nonsharable_collection.id],
                               admin_set_id: admin_set.id)
  end

  subject(:work_permission_service) { described_class.new(object: work, ability: ability) }

  # defined for expectations
  let(:admin_set_manager) { Hash[id: admin_set.id, name: mgr1.user_key] }
  let(:admin_set_creator) { Hash[id: admin_set.id, name: coll_creator.user_key] }
  let(:sharable_coll1_manager) { Hash[id: sharable_coll1.id, name: mgr2.user_key] }
  let(:sharable_coll1_creator) { Hash[id: sharable_coll1.id, name: coll_creator.user_key] }
  let(:sharable_coll2_manager) { Hash[id: sharable_coll2.id, name: mgr3.user_key] }
  let(:sharable_coll2_creator) { Hash[id: sharable_coll2.id, name: coll_creator.user_key] }
  let(:sharable_coll2_viewer) { Hash[id: sharable_coll2.id, name: vw3.user_key] }
  let(:nonsharable_coll_manager) { Hash[id: nonsharable_collection.id, name: mgr4.user_key] }
  let(:nonsharable_coll_creator) { Hash[id: nonsharable_collection.id, name: coll_creator.user_key] }

  describe '#initialize' do
    it 'responds to #depositor and #unauthorized_collection_managers' do
      expect(work_permission_service).to respond_to(:depositor)
      expect(work_permission_service).to respond_to(:unauthorized_collection_managers)
      expect(work_permission_service.depositor).to eq(my_user.user_key)
    end
  end

  describe '#cannot_edit_permissions?' do
    context 'validating which collection managers user may manage' do
      it 'allows user to change managers from authorized collection' do
        expect(work_permission_service.unauthorized_collection_managers).not_to include(sharable_coll1_manager)
        expect(work_permission_service.cannot_edit_permissions?(Hash[name: mgr2.name, type: 'person', access: 'edit'])).to eq false
      end

      it 'restricts user from changing managers from unauthorized collections' do
        expect(work_permission_service.unauthorized_collection_managers).to include(admin_set_manager, admin_set_creator, sharable_coll2_manager, sharable_coll2_creator)
        expect(work_permission_service.cannot_edit_permissions?(Hash[name: mgr1.name, type: 'person', access: 'edit'])).to eq true
        expect(work_permission_service.cannot_edit_permissions?(Hash[name: mgr3.name, type: 'person', access: 'edit'])).to eq true
      end

      it 'restricts user from changing managers which are in both authorized & unauthorized collections' do
        expect(work_permission_service.unauthorized_collection_managers).not_to include(sharable_coll1_creator)
        expect(work_permission_service.cannot_edit_permissions?(Hash[name: coll_creator.name, type: 'person', access: 'edit'])).to eq true
      end

      it 'allows user to change managers not from sharable collections' do
        expect(work_permission_service.unauthorized_collection_managers).not_to include(nonsharable_coll_manager)
        expect(work_permission_service.cannot_edit_permissions?(Hash[name: mgr4.name, type: 'person', access: 'edit'])).to eq false
        expect(work_permission_service.cannot_edit_permissions?(Hash[name: mgr5.name, type: 'person', access: 'edit'])).to eq false
      end

      it 'allows user to change non-manager permissions an unauthorized collection' do
        expect(work_permission_service.unauthorized_collection_managers).not_to include(sharable_coll2_viewer)
        expect(work_permission_service.cannot_edit_permissions?(Hash[name: vw3.name, type: 'person', access: 'read'])).to eq false
      end
    end
  end

  describe '#excluded_permission?' do
    context 'for an excluded permission' do
      let(:permission_hash) { Hash[name: my_user.name, type: 'person', access: 'edit'] }

      it 'returns true' do
        expect(work_permission_service.excluded_permission?(permission_hash)).to eq true
      end
    end

    context 'for an allowed permission' do
      let(:permission_hash) { Hash[name: mgr1.name, type: 'person', access: 'edit'] }

      it 'returns false' do
        expect(work_permission_service.excluded_permission?(permission_hash)).to eq false
      end
    end
  end
end
