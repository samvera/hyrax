# frozen_string_literal: true
require 'cancan/matchers'

RSpec.describe Hyrax::Ability do
  subject(:ability) { Ability.new(current_user) }
  let(:user) { create(:user) }
  let(:current_user) { user }
  let(:collection_type) { FactoryBot.create(:collection_type) }
  let!(:collection) { create(:collection_lw, with_permission_template: true, collection_type: collection_type) }
  let(:permission_template) { collection.permission_template }
  let!(:permission_template_access) do
    create(:permission_template_access,
           :manage,
           permission_template: permission_template,
           agent_type: 'group',
           agent_id: 'manage_group')
  end

  context 'when admin user' do
    let(:user) { FactoryBot.create(:admin) }

    it 'allows all template abilities' do
      is_expected.to be_able_to(:manage, Hyrax::PermissionTemplate)
      is_expected.to be_able_to(:create, permission_template)
      is_expected.to be_able_to(:edit, permission_template)
      is_expected.to be_able_to(:update, permission_template)
      is_expected.to be_able_to(:destroy, permission_template)
    end

    it 'allows all template access abilities' do
      is_expected.to be_able_to(:manage, Hyrax::PermissionTemplateAccess)
      is_expected.to be_able_to(:create, permission_template_access)
      is_expected.to be_able_to(:edit, permission_template_access)
      is_expected.to be_able_to(:update, permission_template_access)
      is_expected.to be_able_to(:destroy, permission_template_access)
    end
  end

  context 'when user has manage access for the source' do
    before do
      create(:permission_template_access,
             :manage,
             permission_template: permission_template,
             agent_type: 'user',
             agent_id: user.user_key)
      collection.permission_template.reset_access_controls_for(
        collection: collection, interpret_visibility: true
      )
    end

    it 'allows most template abilities' do
      is_expected.to be_able_to(:create, permission_template)
      is_expected.to be_able_to(:edit, permission_template)
      is_expected.to be_able_to(:update, permission_template)
      is_expected.to be_able_to(:destroy, permission_template)
    end

    it 'denies manage ability for template' do
      is_expected.not_to be_able_to(:manage, Hyrax::PermissionTemplate)
    end

    it 'allows most template access abilities' do
      is_expected.to be_able_to(:create, permission_template_access)
      is_expected.to be_able_to(:edit, permission_template_access)
      is_expected.to be_able_to(:update, permission_template_access)
      is_expected.to be_able_to(:destroy, permission_template_access)
    end

    it 'denies manage ability for template access' do
      is_expected.not_to be_able_to(:manage, Hyrax::PermissionTemplateAccess)
    end
  end

  context 'when user has deposit access for the source' do
    before do
      create(:permission_template_access,
             :deposit,
             permission_template: permission_template,
             agent_type: 'user',
             agent_id: user.user_key)
      collection.permission_template.reset_access_controls_for(
        collection: collection, interpret_visibility: true
      )
    end

    it 'denies all template abilities' do
      is_expected.not_to be_able_to(:manage, Hyrax::PermissionTemplate)
      is_expected.not_to be_able_to(:create, permission_template)
      is_expected.not_to be_able_to(:edit, permission_template)
      is_expected.not_to be_able_to(:update, permission_template)
      is_expected.not_to be_able_to(:destroy, permission_template)
    end

    it 'denies all template access abilities' do
      is_expected.not_to be_able_to(:manage, Hyrax::PermissionTemplateAccess)
      is_expected.not_to be_able_to(:create, permission_template_access)
      is_expected.not_to be_able_to(:edit, permission_template_access)
      is_expected.not_to be_able_to(:update, permission_template_access)
      is_expected.not_to be_able_to(:destroy, permission_template_access)
    end
  end

  context 'when user has view access for the source' do
    before do
      create(:permission_template_access,
             :view,
             permission_template: permission_template,
             agent_type: 'user',
             agent_id: user.user_key)
      collection.permission_template.reset_access_controls_for(
        collection: collection, interpret_visibility: true
      )
    end

    it 'denies all template abilities' do
      is_expected.not_to be_able_to(:manage, Hyrax::PermissionTemplate)
      is_expected.not_to be_able_to(:create, permission_template)
      is_expected.not_to be_able_to(:edit, permission_template)
      is_expected.not_to be_able_to(:update, permission_template)
      is_expected.not_to be_able_to(:destroy, permission_template)
    end

    it 'denies all template access abilities' do
      is_expected.not_to be_able_to(:manage, Hyrax::PermissionTemplateAccess)
      is_expected.not_to be_able_to(:create, permission_template_access)
      is_expected.not_to be_able_to(:edit, permission_template_access)
      is_expected.not_to be_able_to(:update, permission_template_access)
      is_expected.not_to be_able_to(:destroy, permission_template_access)
    end
  end

  context 'when user has no special access' do
    it 'denies all template abilities' do
      is_expected.not_to be_able_to(:manage, Hyrax::PermissionTemplate)
      is_expected.not_to be_able_to(:create, permission_template)
      is_expected.not_to be_able_to(:edit, permission_template)
      is_expected.not_to be_able_to(:update, permission_template)
      is_expected.not_to be_able_to(:destroy, permission_template)
    end

    it 'denies all template access abilities' do
      is_expected.not_to be_able_to(:manage, Hyrax::PermissionTemplateAccess)
      is_expected.not_to be_able_to(:create, permission_template_access)
      is_expected.not_to be_able_to(:edit, permission_template_access)
      is_expected.not_to be_able_to(:update, permission_template_access)
      is_expected.not_to be_able_to(:destroy, permission_template_access)
    end
  end
end
