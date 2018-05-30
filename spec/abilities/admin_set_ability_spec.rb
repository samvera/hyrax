require 'cancan/matchers'

RSpec.describe 'AdminSetAbility' do
  subject { ability }

  let(:ability) { Ability.new(current_user) }
  let(:user) { create(:user) }
  let(:current_user) { user }
  let(:admin_set) { create(:admin_set, edit_users: [user], with_permission_template: true) }

  context 'when user who created the admin set' do
    it 'allows the edit_users to edit and read' do
      is_expected.to be_able_to(:read, admin_set)
      is_expected.to be_able_to(:edit, admin_set)
    end
  end

  context 'when admin user' do
    let(:user) { FactoryBot.create(:admin) }
    let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

    it 'allows all abilities' do # rubocop:disable RSpec/ExampleLength
      is_expected.to be_able_to(:manage, AdminSet)
      is_expected.to be_able_to(:manage_any, AdminSet)
      is_expected.to be_able_to(:create_any, AdminSet)
      is_expected.to be_able_to(:create, AdminSet)
      is_expected.to be_able_to(:view_admin_show_any, AdminSet)
      is_expected.to be_able_to(:edit, admin_set)
      is_expected.to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:update, admin_set)
      is_expected.to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:destroy, admin_set)
      is_expected.to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:deposit, admin_set)
      is_expected.to be_able_to(:deposit, solr_document)
      is_expected.to be_able_to(:view_admin_show, admin_set)
      is_expected.to be_able_to(:view_admin_show, solr_document)
      is_expected.to be_able_to(:read, admin_set) # admins can do everything
      is_expected.to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
    end
  end

  context 'when admin set manager' do
    let!(:admin_set) { create(:admin_set, id: 'as_mu', with_permission_template: true) }
    let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

    before do
      create(:permission_template_access,
             :manage,
             permission_template: admin_set.permission_template,
             agent_type: 'user',
             agent_id: user.user_key)
      admin_set.reset_access_controls!
    end

    it 'allows most abilities' do # rubocop:disable RSpec/ExampleLength
      is_expected.to be_able_to(:manage_any, AdminSet)
      is_expected.to be_able_to(:view_admin_show_any, AdminSet)
      is_expected.to be_able_to(:edit, admin_set) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:edit, solr_document)
      is_expected.to be_able_to(:update, admin_set) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:update, solr_document)
      is_expected.to be_able_to(:destroy, admin_set) # defined in solr_document_ability.rb
      is_expected.to be_able_to(:destroy, solr_document)
      is_expected.to be_able_to(:deposit, admin_set)
      is_expected.to be_able_to(:deposit, solr_document)
      is_expected.to be_able_to(:view_admin_show, admin_set)
      is_expected.to be_able_to(:view_admin_show, solr_document)
      is_expected.to be_able_to(:read, admin_set) # edit access grants read and write
      is_expected.to be_able_to(:read, solr_document) # edit access grants read and write # defined in solr_document_ability.rb
    end

    it 'denies manage ability' do
      is_expected.not_to be_able_to(:manage, AdminSet)
      is_expected.not_to be_able_to(:create_any, AdminSet) # granted by collection type, not collection
      is_expected.not_to be_able_to(:create, AdminSet)
    end
  end

  context 'when admin set depositor' do
    let!(:admin_set) { create(:admin_set, id: 'as_du', with_permission_template: true) }
    let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

    before do
      create(:permission_template_access,
             :deposit,
             permission_template: admin_set.permission_template,
             agent_type: 'user',
             agent_id: user.user_key)
      admin_set.reset_access_controls!
    end

    it 'allows deposit related abilities' do
      is_expected.to be_able_to(:view_admin_show_any, AdminSet)
      is_expected.to be_able_to(:deposit, admin_set)
      is_expected.to be_able_to(:deposit, solr_document)
      is_expected.to be_able_to(:view_admin_show, admin_set)
      is_expected.to be_able_to(:view_admin_show, solr_document)
    end

    it 'denies non-deposit related abilities' do # rubocop:disable RSpec/ExampleLength
      is_expected.not_to be_able_to(:manage, AdminSet)
      is_expected.not_to be_able_to(:manage_any, AdminSet)
      is_expected.not_to be_able_to(:create_any, AdminSet) # granted by collection type, not collection
      is_expected.not_to be_able_to(:create, AdminSet)
      is_expected.not_to be_able_to(:edit, admin_set)
      is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:update, admin_set)
      is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:destroy, admin_set)
      is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:read, admin_set) # no public page for admin sets
      is_expected.not_to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
    end
  end

  context 'when admin set viewer' do
    let!(:admin_set) { create(:admin_set, id: 'as_vu', with_permission_template: true) }
    let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

    before do
      create(:permission_template_access,
             :view,
             permission_template: admin_set.permission_template,
             agent_type: 'user',
             agent_id: user.user_key)
      admin_set.reset_access_controls!
    end

    it 'allows viewing only ability' do
      is_expected.to be_able_to(:view_admin_show_any, AdminSet)
      is_expected.to be_able_to(:view_admin_show, admin_set)
    end

    it 'denies most abilities' do # rubocop:disable RSpec/ExampleLength
      is_expected.not_to be_able_to(:manage, AdminSet)
      is_expected.not_to be_able_to(:manage_any, AdminSet)
      is_expected.not_to be_able_to(:create_any, AdminSet) # granted by collection type, not collection
      is_expected.not_to be_able_to(:create, AdminSet)
      is_expected.not_to be_able_to(:edit, admin_set)
      is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:update, admin_set)
      is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:destroy, admin_set)
      is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:deposit, admin_set)
      is_expected.not_to be_able_to(:deposit, solr_document)
      is_expected.not_to be_able_to(:read, admin_set) # no public page for admin sets
      is_expected.not_to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
    end
  end

  context 'when user has no special access' do
    let(:admin_set) { create(:admin_set, id: 'as', with_permission_template: true) }
    let!(:solr_document) { SolrDocument.new(admin_set.to_solr) }

    it 'denies all abilities' do # rubocop:disable RSpec/ExampleLength
      is_expected.not_to be_able_to(:manage, AdminSet)
      is_expected.not_to be_able_to(:manage_any, AdminSet)
      is_expected.not_to be_able_to(:create_any, AdminSet) # granted by collection type, not collection
      is_expected.not_to be_able_to(:create, AdminSet)
      is_expected.not_to be_able_to(:view_admin_show_any, AdminSet)
      is_expected.not_to be_able_to(:edit, admin_set)
      is_expected.not_to be_able_to(:edit, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:update, admin_set)
      is_expected.not_to be_able_to(:update, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:destroy, admin_set)
      is_expected.not_to be_able_to(:destroy, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:deposit, admin_set)
      is_expected.not_to be_able_to(:deposit, solr_document) # defined in solr_document_ability.rb
      is_expected.not_to be_able_to(:view_admin_show, admin_set)
      is_expected.not_to be_able_to(:view_admin_show, solr_document)
      is_expected.not_to be_able_to(:read, admin_set) # no public page for admin sets
      is_expected.not_to be_able_to(:read, solr_document) # defined in solr_document_ability.rb
    end
  end
end
