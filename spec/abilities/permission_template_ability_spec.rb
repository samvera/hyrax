# frozen_string_literal: true
require 'cancan/matchers'

RSpec.describe Hyrax::Ability do
  subject(:ability) { Ability.new(current_user) }
  let(:user) { create(:user) }
  let(:current_user) { user }
  let(:collection_type) { FactoryBot.create(:collection_type) }
  let!(:collection) { valkyrie_create(:hyrax_collection, collection_type: collection_type, access_grants: [access_grant]) }
  let(:access_grant) { { agent_type: 'group', access: 'manage', agent_id: 'manage_group' } }
  let(:permission_template) { Hyrax::PermissionTemplate.find_by(source_id: collection.id) }
  let(:permission_template_access) do
    Hyrax::PermissionTemplateAccess.find_by(permission_template_id: permission_template.id.to_s,
                                            agent_type: access_grant[:agent_type],
                                            agent_id: access_grant[:agent_id],
                                            access: access_grant[:access])
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
    let(:access_grant) { { agent_type: 'user', access: 'manage', agent_id: user.user_key } }

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
    let(:access_grant) { { agent_type: 'user', access: 'deposit', agent_id: user.user_key } }

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
    let(:access_grant) { { agent_type: 'user', access: 'view', agent_id: user.user_key } }

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
