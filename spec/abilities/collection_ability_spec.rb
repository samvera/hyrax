# frozen_string_literal: true
require 'cancan/matchers'

RSpec.describe Hyrax::Ability, :clean_repo do
  subject { ability }

  let(:ability) { Ability.new(current_user) }
  let(:user) { FactoryBot.create(:user, email: 'user@example.com') }
  let(:current_user) { user }
  let(:collection_type) { FactoryBot.create(:collection_type) }
  let(:collection_type_gid) { collection_type.to_global_id }

  # abilities always test Hyrax::PcdmCollection, but only test Collection
  # if it is configured as the collection_model
  around(:each) do |example|
    current_collection_model = Hyrax.config.collection_model
    Hyrax.config.collection_model = 'Collection' unless Hyrax.config.disable_wings

    example.run
    Hyrax.config.collection_model = current_collection_model
  end

  # rubocop:disable RSpec/ExampleLength
  context 'when admin user' do
    let(:current_user) { admin }
    let(:admin) { FactoryBot.create(:admin, email: 'admin@example.com') }

    context 'and collection is an ActiveFedora::Base', :active_fedora do
      let!(:collection) do
        FactoryBot.build(:collection_lw, id: 'col_au',
                                         user: user,
                                         with_permission_template: true,
                                         collection_type: collection_type)
      end
      let!(:solr_document) { SolrDocument.new(collection.to_solr) }

      it 'can do everything' do
        is_expected.to be_able_to(:manage, Collection)
        is_expected.to be_able_to(:manage_any, Collection)
        is_expected.to be_able_to(:create_any, Collection)
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        is_expected.to be_able_to(:edit, collection)
        is_expected.to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
        is_expected.to be_able_to(:update, collection)
        is_expected.to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
        is_expected.to be_able_to(:destroy, collection)
        is_expected.to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
        is_expected.to be_able_to(:deposit, collection)
        is_expected.to be_able_to(:deposit, solr_document)
        is_expected.to be_able_to(:view_admin_show, collection)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:read, collection)
        is_expected.to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
      end
    end

    context 'and collection is a valkyrie resource' do
      let!(:collection) do
        FactoryBot.valkyrie_create(:hyrax_collection,
                                   user: user,
                                   collection_type_gid: collection_type_gid)
      end
      let!(:solr_document) { SolrDocument.new(Hyrax::PcdmCollectionIndexer.new(resource: collection).to_solr) }

      it 'can do everything' do
        is_expected.to be_able_to(:manage, Hyrax::PcdmCollection)
        is_expected.to be_able_to(:manage_any, Hyrax::PcdmCollection)
        is_expected.to be_able_to(:create_any, Hyrax::PcdmCollection)
        is_expected.to be_able_to(:view_admin_show_any, Hyrax::PcdmCollection)
        is_expected.to be_able_to(:edit, collection)
        is_expected.to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
        is_expected.to be_able_to(:update, collection)
        is_expected.to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
        is_expected.to be_able_to(:destroy, collection)
        is_expected.to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
        is_expected.to be_able_to(:deposit, collection)
        is_expected.to be_able_to(:deposit, solr_document)
        is_expected.to be_able_to(:view_admin_show, collection)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:read, collection)
        is_expected.to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
      end
    end
  end

  context 'when collection manager' do
    let(:current_user) { manager }
    let(:manager) { FactoryBot.create(:user, email: 'manager@example.com') }

    context 'and collection is an ActiveFedora::Base', :active_fedora do
      let!(:collection) do
        FactoryBot.build(:collection_lw, id: 'col_mu',
                                         user: user,
                                         with_permission_template: true,
                                         collection_type: collection_type)
      end
      let!(:solr_document) { SolrDocument.new(collection.to_solr) }

      before do
        FactoryBot.create(:permission_template_access,
                          :manage,
                          permission_template: collection.permission_template,
                          agent_type: 'user',
                          agent_id: manager.user_key)
        collection.permission_template.reset_access_controls_for(collection: collection)
      end

      it 'can do everything for the collection they manage' do
        is_expected.to be_able_to(:manage_any, Collection)
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        is_expected.to be_able_to(:edit, collection)
        is_expected.to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
        is_expected.to be_able_to(:update, collection)
        is_expected.to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
        is_expected.to be_able_to(:destroy, collection)
        is_expected.to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
        is_expected.to be_able_to(:deposit, collection)
        is_expected.to be_able_to(:deposit, solr_document)
        is_expected.to be_able_to(:view_admin_show, collection)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:read, collection) # edit access grants read and write
        is_expected.to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
      end

      it 'cannot manage all collections' do
        is_expected.not_to be_able_to(:manage, Collection)
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

      it 'can do everything for the collection they manage' do
        is_expected.to be_able_to(:manage_any, Hyrax::PcdmCollection)
        is_expected.to be_able_to(:view_admin_show_any, Hyrax::PcdmCollection)
        is_expected.to be_able_to(:edit, collection)
        is_expected.to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
        is_expected.to be_able_to(:update, collection)
        is_expected.to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
        is_expected.to be_able_to(:destroy, collection)
        is_expected.to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
        is_expected.to be_able_to(:deposit, collection)
        is_expected.to be_able_to(:deposit, solr_document)
        is_expected.to be_able_to(:view_admin_show, collection)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:read, collection) # edit access grants read and write
        is_expected.to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
      end

      it 'cannot manage all collections' do
        is_expected.not_to be_able_to(:manage, Hyrax::PcdmCollection)
      end
    end
  end

  context 'when collection depositor' do
    let(:current_user) { depositor }
    let(:depositor) { FactoryBot.create(:user, email: 'depositor@example.com') }

    context 'and collection is an ActiveFedora::Base', :active_fedora do
      let!(:collection) do
        FactoryBot.build(:collection_lw, id: 'col_du',
                                         user: user,
                                         with_permission_template: true,
                                         collection_type: collection_type)
      end
      let!(:solr_document) { SolrDocument.new(collection.to_solr) }

      before do
        FactoryBot.create(:permission_template_access,
                          :deposit,
                          permission_template: collection.permission_template,
                          agent_type: 'user',
                          agent_id: depositor.user_key)
        collection.permission_template.reset_access_controls_for(
          collection: collection, interpret_visibility: true
        )
      end

      it 'can view and deposit in the collection where they are a depositor' do
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        is_expected.to be_able_to(:deposit, collection)
        is_expected.to be_able_to(:deposit, solr_document)
        is_expected.to be_able_to(:view_admin_show, collection)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:read, collection)
        is_expected.to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
      end

      it 'cannot edit or update collections where they are a depositor' do
        is_expected.not_to be_able_to(:manage, Collection)
        is_expected.not_to be_able_to(:manage_any, Collection)
        is_expected.not_to be_able_to(:edit, collection)
        is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:update, collection)
        is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:destroy, collection)
        is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
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

      it 'can view and deposit in the collection where they are a depositor' do
        is_expected.to be_able_to(:view_admin_show_any, Hyrax::PcdmCollection)
        is_expected.to be_able_to(:deposit, collection)
        is_expected.to be_able_to(:deposit, solr_document)
        is_expected.to be_able_to(:view_admin_show, collection)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:read, collection)
        is_expected.to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
      end

      it 'cannot edit or update collections where they are a depositor' do
        is_expected.not_to be_able_to(:manage, Hyrax::PcdmCollection)
        is_expected.not_to be_able_to(:manage_any, Hyrax::PcdmCollection)
        is_expected.not_to be_able_to(:edit, collection)
        is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:update, collection)
        is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:destroy, collection)
        is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
      end
    end
  end

  context 'when collection viewer' do
    let(:current_user) { viewer }
    let(:viewer) { FactoryBot.create(:user, email: 'viewer@example.com') }

    context 'and collection is an ActiveFedora::Base', :active_fedora do
      let!(:collection) do
        FactoryBot.build(:collection_lw, id: 'col_vu',
                                         user: user,
                                         with_permission_template: true,
                                         collection_type: collection_type)
      end
      let!(:solr_document) { SolrDocument.new(collection.to_solr) }

      before do
        FactoryBot.create(:permission_template_access,
                          :view,
                          permission_template: collection.permission_template,
                          agent_type: 'user',
                          agent_id: viewer.user_key)
        collection.permission_template.reset_access_controls_for(collection: collection)
      end

      it 'can view the collection where they are a viewer' do
        is_expected.to be_able_to(:view_admin_show_any, Collection)
        is_expected.to be_able_to(:view_admin_show, collection)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:read, collection)
        is_expected.to be_able_to(:read, solr_document)
      end

      it 'cannot modify in any way collections where they are a viewer' do
        is_expected.not_to be_able_to(:manage, Collection)
        is_expected.not_to be_able_to(:manage_any, Collection)
        is_expected.not_to be_able_to(:edit, collection)
        is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:update, collection)
        is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:destroy, collection)
        is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:deposit, collection)
        is_expected.not_to be_able_to(:deposit, solr_document)
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

      it 'can view the collection where they are a viewer' do
        is_expected.to be_able_to(:view_admin_show_any, Hyrax::PcdmCollection)
        is_expected.to be_able_to(:view_admin_show, collection)
        is_expected.to be_able_to(:view_admin_show, solr_document)
        is_expected.to be_able_to(:read, collection)
        is_expected.to be_able_to(:read, solr_document)
      end

      it 'cannot modify in any way collections where they are a viewer' do
        is_expected.not_to be_able_to(:manage, Hyrax::PcdmCollection)
        is_expected.not_to be_able_to(:manage_any, Hyrax::PcdmCollection)
        is_expected.not_to be_able_to(:edit, collection)
        is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:update, collection)
        is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:destroy, collection)
        is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:deposit, collection)
        is_expected.not_to be_able_to(:deposit, solr_document)
      end
    end
  end

  context 'when user has no special access' do
    let(:current_user) { other_user }
    let(:other_user) { FactoryBot.create(:user, email: 'other_user@example.com') }

    context 'and collection is an ActiveFedora::Base', :active_fedora do
      let!(:collection) do
        FactoryBot.create(:collection_lw, id: 'as',
                                          user: user,
                                          with_permission_template: true,
                                          collection_type: collection_type)
      end
      let!(:solr_document) { SolrDocument.new(collection.to_solr) }

      it 'cannot view or modify in any way collections with restricted access' do
        is_expected.not_to be_able_to(:manage, Collection)
        is_expected.not_to be_able_to(:manage_any, Collection)
        is_expected.not_to be_able_to(:view_admin_show_any, Collection)
        is_expected.not_to be_able_to(:edit, collection)
        is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:update, collection)
        is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:destroy, collection)
        is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:deposit, collection)
        is_expected.not_to be_able_to(:deposit, solr_document)
        is_expected.not_to be_able_to(:view_admin_show, collection)
        is_expected.not_to be_able_to(:view_admin_show, solr_document)
        is_expected.not_to be_able_to(:read, collection)
        is_expected.not_to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
      end
    end

    context 'and collection is a valkyrie resource' do
      let!(:collection) do
        FactoryBot.valkyrie_create(:hyrax_collection,
                                   user: user,
                                   collection_type_gid: collection_type_gid)
      end
      let!(:solr_document) { SolrDocument.new(Hyrax::PcdmCollectionIndexer.new(resource: collection).to_solr) }

      it 'cannot view or modify in any way collections with restricted access' do
        is_expected.not_to be_able_to(:manage, Hyrax::PcdmCollection)
        is_expected.not_to be_able_to(:manage_any, Hyrax::PcdmCollection)
        is_expected.not_to be_able_to(:view_admin_show_any, Hyrax::PcdmCollection)
        is_expected.not_to be_able_to(:edit, collection)
        is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:update, collection)
        is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:destroy, collection)
        is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
        is_expected.not_to be_able_to(:deposit, collection)
        is_expected.not_to be_able_to(:deposit, solr_document)
        is_expected.not_to be_able_to(:view_admin_show, collection)
        is_expected.not_to be_able_to(:view_admin_show, solr_document)
        is_expected.not_to be_able_to(:read, collection)
        is_expected.not_to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
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
      before { FactoryBot.create(:user_collection_type) }

      it 'allows create_any' do
        is_expected.to be_able_to(:create_any, Collection)
      end
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
