# frozen_string_literal: true
require 'cancan/matchers'

RSpec.describe Hyrax::Ability do
  subject(:ability) { Ability.new(user) }

  describe '.admin_group_name' do
    let(:user) { create(:user) }

    it 'returns the admin group name' do
      expect(subject.admin_group_name).to eq 'admin'
    end
  end

  describe "#registered_user?" do
    subject { ability.send :registered_user? }

    context "with a guest user" do
      let(:user) { create(:user, :guest) }

      it { is_expected.to be false }
    end
  end

  describe "#can_create_any_work?" do
    subject { ability.can_create_any_work? }

    let(:user) { create(:user) }

    context "when user doesn't have deposit into any admin set" do
      it { is_expected.to be false }
    end

    context "when user can deposit into an admin set" do
      let(:permission_template) { create(:permission_template, with_admin_set: true) }

      before do
        # Grant the user access to deposit into an admin set.
        create(:permission_template_access,
               :deposit,
               permission_template: permission_template,
               agent_type: 'user',
               agent_id: user.user_key)
      end
      it { is_expected.to be true }
    end
  end

  describe "can?(:review, :submissions)", :clean_repo do
    subject { ability.can?(:review, :submissions) }

    let(:role) { Sipity::Role.create(name: role_name) }
    let(:user) { create(:user) }
    let(:permission_template) { create(:permission_template, with_active_workflow: true) }
    let(:workflow) { permission_template.active_workflow }

    before do
      workflow.workflow_roles.create(role: role)
      # We are testing that this workflow role is removed
      Hyrax::Workflow::PermissionGenerator.call(roles: role,
                                                workflow: workflow,
                                                agents: user)
    end

    context "as an administrator" do
      # Assign a role that should not grant review ability
      let(:role_name) { 'depositing' }

      before do
        Sipity::Role.create(name: 'approving')
        # Admin-ify the user
        allow(user).to receive_messages(groups: ['admin', 'registered'])
      end

      it { is_expected.to be true }
    end

    context "as a depositor" do
      let(:role_name) { 'depositing' }

      before do
        Sipity::Role.create(name: 'approving')
      end

      it { is_expected.to be false }
    end

    context "as an approver" do
      let(:role_name) { 'approving' }

      it { is_expected.to be true }
    end
  end

  describe "a user with no roles" do
    let(:user) { nil }

    it { is_expected.not_to be_able_to(:update, ContentBlock) }
    it { is_expected.not_to be_able_to(:create, AdminSet) }
    it { is_expected.to be_able_to(:read, ContentBlock) }
    unless Hyrax.config.disable_wings
      it { is_expected.to be_able_to(:read, GenericWork) }
      it { is_expected.to be_able_to(:stats, GenericWork) }
      it { is_expected.to be_able_to(:citation, GenericWork) }
    end
  end

  describe "a registered user" do
    let(:user) { create(:user) }

    it { is_expected.not_to be_able_to(:update, ContentBlock) }
    it { is_expected.to be_able_to(:read, ContentBlock) }
    it { is_expected.not_to be_able_to(:read, Hyrax::Statistics) }
    it { is_expected.not_to be_able_to(:read, :admin_dashboard) }
    it { is_expected.not_to be_able_to(:create, AdminSet) }
    it { is_expected.not_to be_able_to(:update, :appearance) }
  end

  describe "a user in the admin group" do
    let(:user) { create(:user) }

    before { allow(user).to receive_messages(groups: ['admin', 'registered']) }
    it { is_expected.to be_able_to(:update, ContentBlock) }
    it { is_expected.to be_able_to(:read, ContentBlock) }
    it { is_expected.to be_able_to(:read, Hyrax::Statistics) }
    it { is_expected.to be_able_to(:download, 'abcd123') } # an id for a work/FileSet
    it { is_expected.to be_able_to(:edit, 'abcd123') } # an id for a work/FileSet
    it { is_expected.to be_able_to(:destroy, 'abcd123') } # an id for a work/FileSet
    it { is_expected.to be_able_to(:read, :admin_dashboard) }
    it { is_expected.to be_able_to(:manage, AdminSet) }
    it { is_expected.to be_able_to(:create, AdminSet) }
    it { is_expected.to be_able_to(:update, :appearance) }
  end

  describe "AdminSets and PermissionTemplates" do
    let(:permission_template) { build(:permission_template, source_id: admin_set.id) }
    let(:permission_template_access) { build(:permission_template_access, permission_template: permission_template) }
    let(:user) { create(:user) }
    let(:admin_set) { valkyrie_create(:hyrax_admin_set) }

    RSpec.shared_examples 'A user with additional access' do
      it { is_expected.to be_able_to(:edit, admin_set) }
      it { is_expected.to be_able_to(:update, admin_set) }
      it { is_expected.to be_able_to(:destroy, admin_set) }
      it { is_expected.to be_able_to(:create, permission_template) }
      it { is_expected.to be_able_to(:create, permission_template_access) }
    end

    describe 'as admin' do
      let(:user) { create(:user, groups: ['admin']) }

      it '#admin? is true' do
        expect(ability).to be_admin
      end
      it_behaves_like 'A user with additional access'
    end

    describe 'via AdminSet-specific edit_users' do
      let(:admin_set) { valkyrie_create(:hyrax_admin_set, edit_users: [user.user_key]) }
      let(:permission_template) do
        create(:permission_template, source_id: admin_set.id)
      end

      it '#admin? is false' do
        expect(ability).not_to be_admin
      end

      it 'A user who can manage an AdminSet' do
        create(:permission_template_access,
               :manage,
               permission_template: permission_template,
               agent_type: 'user',
               agent_id: user.user_key)
        is_expected.to be_able_to(:manage_any, AdminSet)
      end
      it_behaves_like 'A user with additional access'
    end

    describe "a user without edit access" do
      it { is_expected.not_to be_able_to(:edit, admin_set) }
      it { is_expected.not_to be_able_to(:update, admin_set) }
      it { is_expected.not_to be_able_to(:destroy, admin_set) }
      it { is_expected.not_to be_able_to(:create, permission_template) }
      it { is_expected.not_to be_able_to(:create, permission_template_access) }
    end
  end
end
