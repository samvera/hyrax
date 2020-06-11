# frozen_string_literal: true
require 'cancan/matchers'

RSpec.describe Hyrax::Ability do
  subject { ability }

  let(:ability) { Ability.new(current_user) }
  let(:user) { create(:user) }
  let(:current_user) { user }
  let(:collection_type_gid) { create(:collection_type).gid }

  context 'when admin user' do
    let(:user) { FactoryBot.create(:admin) }
    let!(:collection) { build(:collection_lw, id: 'col_au', with_permission_template: true, collection_type_gid: collection_type_gid) }
    let!(:solr_document) { SolrDocument.new(collection.to_solr) }

    it 'allows all abilities' do # rubocop:disable RSpec/ExampleLength
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

  context 'when collection manager' do
    let!(:collection) { build(:collection_lw, id: 'col_mu', with_permission_template: true, collection_type_gid: collection_type_gid) }
    let!(:solr_document) { SolrDocument.new(collection.to_solr) }

    before do
      create(:permission_template_access,
             :manage,
             permission_template: collection.permission_template,
             agent_type: 'user',
             agent_id: user.user_key)
      collection.reset_access_controls!
    end

    it 'allows most abilities' do # rubocop:disable RSpec/ExampleLength
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

    it 'denies manage ability' do
      is_expected.not_to be_able_to(:manage, Collection)
    end
  end

  context 'when collection depositor' do
    let!(:collection) { build(:collection_lw, id: 'col_du', with_permission_template: true, collection_type_gid: collection_type_gid) }
    let!(:solr_document) { SolrDocument.new(collection.to_solr) }

    before do
      create(:permission_template_access,
             :deposit,
             permission_template: collection.permission_template,
             agent_type: 'user',
             agent_id: user.user_key)
      collection.reset_access_controls!
    end

    it 'allows deposit related abilities' do
      is_expected.to be_able_to(:view_admin_show_any, Collection)
      is_expected.to be_able_to(:deposit, collection)
      is_expected.to be_able_to(:deposit, solr_document)
      is_expected.to be_able_to(:view_admin_show, collection)
      is_expected.to be_able_to(:view_admin_show, solr_document)
    end

    it 'denies non-deposit related abilities' do # rubocop:disable RSpec/ExampleLength
      is_expected.not_to be_able_to(:manage, Collection)
      is_expected.not_to be_able_to(:manage_any, Collection)
      is_expected.not_to be_able_to(:edit, collection)
      is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:update, collection)
      is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:destroy, collection)
      is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:read, collection)
      is_expected.not_to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
    end
  end

  context 'when collection viewer' do
    let!(:collection) { build(:collection_lw, id: 'col_vu', with_permission_template: true, collection_type_gid: collection_type_gid) }
    let!(:solr_document) { SolrDocument.new(collection.to_solr) }

    before do
      create(:permission_template_access,
             :view,
             permission_template: collection.permission_template,
             agent_type: 'user',
             agent_id: user.user_key)
      collection.reset_access_controls!
    end

    it 'allows viewing only ability' do
      is_expected.to be_able_to(:view_admin_show_any, Collection)
      is_expected.to be_able_to(:view_admin_show, collection)
      is_expected.to be_able_to(:view_admin_show, solr_document)
      is_expected.to be_able_to(:read, collection)
      is_expected.to be_able_to(:read, solr_document)
    end

    it 'denies most abilities' do # rubocop:disable RSpec/ExampleLength
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

  context 'when user has no special access' do
    let!(:collection) { create(:collection_lw, id: 'as', with_permission_template: true, collection_type_gid: collection_type_gid) }
    let!(:solr_document) { SolrDocument.new(collection.to_solr) }

    it 'denies all abilities' do # rubocop:disable RSpec/ExampleLength
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
      before do
        create(:user_collection_type)
      end

      it 'allows create_any' do
        is_expected.to be_able_to(:create_any, Collection)
      end
    end
  end
end
