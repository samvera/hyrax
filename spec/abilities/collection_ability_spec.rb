# frozen_string_literal: true
require 'cancan/matchers'

RSpec.describe Hyrax::Ability, :clean_repo do
  subject { ability }

  let(:ability) { Ability.new(current_user) }
  let(:user) { create(:user, email: 'user@example.com') }
  let(:current_user) { user }
  let(:collection_type) { FactoryBot.create(:collection_type) }
  let(:collection_type_gid) { collection_type.to_global_id }

  context 'when admin user' do
    let(:current_user) { admin }
    let(:admin) { FactoryBot.create(:admin, email: 'admin@example.com') }

    context 'and collection is an ActiveFedora::Base' do
      let!(:collection) do
        FactoryBot.build(:collection_lw, id: 'col_au',
                                         user: user,
                                         with_permission_template: true,
                                         collection_type: collection_type)
      end
      let!(:solr_document) { SolrDocument.new(collection.to_solr) }

      context 'for abilities open to admins' do
        it { is_expected.to be_able_to(:manage, Collection) }
        it { is_expected.to be_able_to(:manage_any, Collection) }
        it { is_expected.to be_able_to(:create_any, Collection) }
        it { is_expected.to be_able_to(:view_admin_show_any, Collection) }
        it { is_expected.to be_able_to(:edit, collection) }
        it { is_expected.to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:update, collection) }
        it { is_expected.to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:destroy, collection) }
        it { is_expected.to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:deposit, collection) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, collection) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, collection) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end
    end

    context 'and collection is a valkyrie resource' do
      let!(:collection) do
        FactoryBot.valkyrie_create(:hyrax_collection,
                                   user: user,
                                   collection_type_gid: collection_type_gid)
      end
      let!(:solr_document) { SolrDocument.new(Hyrax::PcdmCollectionIndexer.new(resource: collection).to_solr) }

      context 'for abilities open to admins' do
        it { is_expected.to be_able_to(:manage, Hyrax::PcdmCollection) }
        it { is_expected.to be_able_to(:manage_any, Hyrax::PcdmCollection) }
        it { is_expected.to be_able_to(:create_any, Hyrax::PcdmCollection) }
        it { is_expected.to be_able_to(:view_admin_show_any, Collection) }
        it { is_expected.to be_able_to(:edit, collection) }
        it { is_expected.to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:update, collection) }
        it { is_expected.to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:destroy, collection) }
        it { is_expected.to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:deposit, collection) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, collection) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, collection) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end
    end
  end

  context 'when collection manager' do
    let(:current_user) { manager }
    let(:manager) { create(:user, email: 'manager@example.com') }

    context 'and collection is an ActiveFedora::Base' do
      let!(:collection) do
        FactoryBot.build(:collection_lw, id: 'col_mu',
                                         user: user,
                                         with_permission_template: true,
                                         collection_type: collection_type)
      end
      let!(:solr_document) { SolrDocument.new(collection.to_solr) }

      before do
        create(:permission_template_access,
                 :manage,
                 permission_template: collection.permission_template,
                 agent_type: 'user',
                 agent_id: manager.user_key)
        collection.reset_access_controls!
      end

      context 'for abilities open to managers' do
        it { is_expected.to be_able_to(:manage_any, Collection) }
        it { is_expected.to be_able_to(:view_admin_show_any, Collection) }
        it { is_expected.to be_able_to(:edit, collection) }
        it { is_expected.to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:update, collection) }
        it { is_expected.to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:destroy, collection) }
        it { is_expected.to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:deposit, collection) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, collection) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, collection) } # edit access grants read and write
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end

      context 'for abilities NOT open to managers' do
        it { is_expected.not_to be_able_to(:manage, Collection) }
      end
    end

    context 'and collection is a valkyrie resource' do
      let!(:collection) do
        FactoryBot.valkyrie_create(:hyrax_collection,
                                   user: user,
                                   collection_type_gid: collection_type_gid,
                                   access_grants: grants)
      end
      let!(:solr_document) { SolrDocument.new(Hyrax::PcdmCollectionIndexer.new(resource: collection).to_solr) }

      let(:grants) do
        [
          {
            agent_type: Hyrax::PermissionTemplateAccess::USER,
            agent_id: manager.user_key,
            access: Hyrax::PermissionTemplateAccess::MANAGE
          }
        ]
      end

      context 'for abilities open to managers' do
        it { is_expected.to be_able_to(:manage_any, Hyrax::PcdmCollection) }
        it { is_expected.to be_able_to(:view_admin_show_any, Hyrax::PcdmCollection) }
        it { is_expected.to be_able_to(:edit, collection) }
        it { is_expected.to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:update, collection) }
        it { is_expected.to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:destroy, collection) }
        it { is_expected.to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.to be_able_to(:deposit, collection) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, collection) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, collection) } # edit access grants read and write
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end

      context 'for abilities NOT open to managers' do
        it { is_expected.not_to be_able_to(:manage, Hyrax::PcdmCollection) }
      end
    end
  end

  context 'when collection depositor' do
    let(:current_user) { depositor }
    let(:depositor) { create(:user, email: 'depositor@example.com') }

    context 'and collection is an ActiveFedora::Base' do
      let!(:collection) do
        FactoryBot.build(:collection_lw, id: 'col_du',
                                         user: user,
                                         with_permission_template: true,
                                         collection_type: collection_type)
      end
      let!(:solr_document) { SolrDocument.new(collection.to_solr) }

      before do
        create(:permission_template_access,
               :deposit,
               permission_template: collection.permission_template,
               agent_type: 'user',
               agent_id: depositor.user_key)
        collection.reset_access_controls!
      end

      context 'for abilities open to depositor' do
        it { is_expected.to be_able_to(:view_admin_show_any, Collection) }
        it { is_expected.to be_able_to(:deposit, collection) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, collection) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, collection) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end

      context 'for abilities NOT open to depositor' do
        it { is_expected.not_to be_able_to(:manage, Collection) }
        it { is_expected.not_to be_able_to(:manage_any, Collection) }
        it { is_expected.not_to be_able_to(:edit, collection) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, collection) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, collection) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
      end
    end

    context 'and collection is a valkyrie resource' do
      let!(:collection) do
        FactoryBot.valkyrie_create(:hyrax_collection,
                                   user: user,
                                   collection_type_gid: collection_type_gid,
                                   access_grants: grants)
      end
      let!(:solr_document) { SolrDocument.new(Hyrax::PcdmCollectionIndexer.new(resource: collection).to_solr) }

      let(:grants) do
        [
          {
            agent_type: Hyrax::PermissionTemplateAccess::USER,
            agent_id: depositor.user_key,
            access: Hyrax::PermissionTemplateAccess::DEPOSIT
          }
        ]
      end

      context 'for abilities open to depositor' do
        it { is_expected.to be_able_to(:view_admin_show_any, Collection) }
        it { is_expected.to be_able_to(:deposit, collection) }
        it { is_expected.to be_able_to(:deposit, solr_document) }
        it { is_expected.to be_able_to(:view_admin_show, collection) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, collection) }
        it { is_expected.to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end

      context 'for abilities NOT open to depositor' do
        it { is_expected.not_to be_able_to(:manage, Collection) }
        it { is_expected.not_to be_able_to(:manage_any, Collection) }
        it { is_expected.not_to be_able_to(:edit, collection) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, collection) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, collection) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
      end
    end
  end

  context 'when collection viewer' do
    let(:current_user) { viewer }
    let(:viewer) { create(:user, email: 'viewer@example.com') }

    context 'and collection is an ActiveFedora::Base' do
      let!(:collection) do
        FactoryBot.build(:collection_lw, id: 'col_vu',
                                         user: user,
                                         with_permission_template: true,
                                         collection_type: collection_type)
      end
      let!(:solr_document) { SolrDocument.new(collection.to_solr) }

      before do
        create(:permission_template_access,
               :view,
               permission_template: collection.permission_template,
               agent_type: 'user',
               agent_id: viewer.user_key)
        collection.reset_access_controls!
      end

      context 'for abilities open to viewer' do
        it { is_expected.to be_able_to(:view_admin_show_any, Collection) }
        it { is_expected.to be_able_to(:view_admin_show, collection) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, collection) }
        it { is_expected.to be_able_to(:read, solr_document) }
      end

      context 'for abilities NOT open to viewer' do
        it { is_expected.not_to be_able_to(:manage, Collection) }
        it { is_expected.not_to be_able_to(:manage_any, Collection) }
        it { is_expected.not_to be_able_to(:edit, collection) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, collection) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, collection) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:deposit, collection) }
        it { is_expected.not_to be_able_to(:deposit, solr_document) }
      end
    end

    context 'and collection is a valkyrie resource' do
      let!(:collection) do
        FactoryBot.valkyrie_create(:hyrax_collection,
                                   user: user,
                                   collection_type_gid: collection_type_gid,
                                   access_grants: grants)
      end
      let!(:solr_document) { SolrDocument.new(Hyrax::PcdmCollectionIndexer.new(resource: collection).to_solr) }

      let(:grants) do
        [
          {
            agent_type: Hyrax::PermissionTemplateAccess::USER,
            agent_id: viewer.user_key,
            access: Hyrax::PermissionTemplateAccess::VIEW
          }
        ]
      end

      context 'for abilities open to viewer' do
        it { is_expected.to be_able_to(:view_admin_show_any, Hyrax::PcdmCollection) }
        it { is_expected.to be_able_to(:view_admin_show, collection) }
        it { is_expected.to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.to be_able_to(:read, collection) }
        it { is_expected.to be_able_to(:read, solr_document) }
      end

      context 'for abilities NOT open to viewer' do
        it { is_expected.not_to be_able_to(:manage, Hyrax::PcdmCollection) }
        it { is_expected.not_to be_able_to(:manage_any, Hyrax::PcdmCollection) }
        it { is_expected.not_to be_able_to(:edit, collection) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, collection) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, collection) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:deposit, collection) }
        it { is_expected.not_to be_able_to(:deposit, solr_document) }
      end
    end
  end

  context 'when user has no special access' do
    let(:current_user) { other_user }
    let(:other_user) { create(:user, email: 'other_user@example.com') }

    context 'and collection is an ActiveFedora::Base' do
      let!(:collection) do
        FactoryBot.create(:collection_lw, id: 'as',
                                          user: user,
                                          with_permission_template: true,
                                          collection_type: collection_type)
      end
      let!(:solr_document) { SolrDocument.new(collection.to_solr) }

      context 'for abilities NOT open to general user' do
        it { is_expected.not_to be_able_to(:manage, Collection) }
        it { is_expected.not_to be_able_to(:manage_any, Collection) }
        it { is_expected.not_to be_able_to(:view_admin_show_any, Collection) }
        it { is_expected.not_to be_able_to(:edit, collection) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, collection) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, collection) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:deposit, collection) }
        it { is_expected.not_to be_able_to(:deposit, solr_document) }
        it { is_expected.not_to be_able_to(:view_admin_show, collection) }
        it { is_expected.not_to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.not_to be_able_to(:read, collection) }
        it { is_expected.not_to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end
    end

    context 'and collection is a valkyrie resource' do
      let!(:collection) do
        FactoryBot.valkyrie_create(:hyrax_collection,
                                   user: user,
                                   collection_type_gid: collection_type_gid)
      end
      let!(:solr_document) { SolrDocument.new(Hyrax::PcdmCollectionIndexer.new(resource: collection).to_solr) }

      context 'for abilities NOT open to general user' do
        it { is_expected.not_to be_able_to(:manage, Collection) }
        it { is_expected.not_to be_able_to(:manage_any, Collection) }
        it { is_expected.not_to be_able_to(:view_admin_show_any, Collection) }
        it { is_expected.not_to be_able_to(:edit, collection) }
        it { is_expected.not_to be_able_to(:edit, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:update, collection) }
        it { is_expected.not_to be_able_to(:update, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:destroy, collection) }
        it { is_expected.not_to be_able_to(:destroy, solr_document) } # defined in solr_document_ability.rb
        it { is_expected.not_to be_able_to(:deposit, collection) }
        it { is_expected.not_to be_able_to(:deposit, solr_document) }
        it { is_expected.not_to be_able_to(:view_admin_show, collection) }
        it { is_expected.not_to be_able_to(:view_admin_show, solr_document) }
        it { is_expected.not_to be_able_to(:read, collection) }
        it { is_expected.not_to be_able_to(:read, solr_document) } # defined in solr_document_ability.rb
      end
    end
  end

  context 'create_any' do
    # Whether a user can create a collection depends on collection type participants, so need to test separately.

    context 'when there are no collection types that have create access' do
      before do
        # User Collection type is always created and gives all users the ability to create.  To be able to test that
        # particular roles don't automatically give users create abilities, the create access for User Collection type
        # has to be removed.
        uct = Hyrax::CollectionType.find_by(machine_id: Hyrax::CollectionType::USER_COLLECTION_MACHINE_ID)
        if uct.present?
          uctp = Hyrax::CollectionTypeParticipant.find_by(hyrax_collection_type_id: uct.id, access: "create")
          uctp.destroy if uctp.present?
        end
      end

      it 'denies create_any' do
        is_expected.not_to be_able_to(:create_any, Collection)
      end
    end

    context 'when there are collection types that have create access' do
      before { create(:user_collection_type) }

      it 'allows create_any' do
        is_expected.to be_able_to(:create_any, Collection)
      end
    end
  end
end
