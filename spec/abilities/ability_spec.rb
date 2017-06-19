require 'cancan/matchers'

describe 'Hyrax::Ability', type: :model do
  let(:ability) { Ability.new(user) }
  subject { ability }

  describe "#registered_user?" do
    subject { ability.send :registered_user? }
    context "with a guest user" do
      let(:user) { create(:user, :guest) }
      it { is_expected.to be false }
    end
  end

  describe "a user with no roles" do
    let(:user) { nil }
    it { is_expected.not_to be_able_to(:create, TinymceAsset) }
    it { is_expected.not_to be_able_to(:create, ContentBlock) }
    it { is_expected.not_to be_able_to(:update, ContentBlock) }
    it { is_expected.not_to be_able_to(:create, AdminSet) }
    it { is_expected.to be_able_to(:read, ContentBlock) }
    it { is_expected.to be_able_to(:read, GenericWork) }
    it { is_expected.to be_able_to(:stats, GenericWork) }
    it { is_expected.to be_able_to(:citation, GenericWork) }
  end

  describe "a registered user" do
    let(:user) { create(:user) }
    it { is_expected.not_to be_able_to(:create, TinymceAsset) }
    it { is_expected.not_to be_able_to(:create, ContentBlock) }
    it { is_expected.not_to be_able_to(:update, ContentBlock) }
    it { is_expected.to be_able_to(:read, ContentBlock) }
    it { is_expected.not_to be_able_to(:read, Hyrax::Statistics) }
    it { is_expected.not_to be_able_to(:read, :admin_dashboard) }
    it { is_expected.not_to be_able_to(:create, AdminSet) }
  end

  describe "a user in the admin group" do
    let(:user) { create(:user) }
    before { allow(user).to receive_messages(groups: ['admin', 'registered']) }
    it { is_expected.to be_able_to(:create, TinymceAsset) }
    it { is_expected.to be_able_to(:create, ContentBlock) }
    it { is_expected.to be_able_to(:update, ContentBlock) }
    it { is_expected.to be_able_to(:read, ContentBlock) }
    it { is_expected.to be_able_to(:read, Hyrax::Statistics) }
    it { is_expected.to be_able_to(:download, 'abcd123') } # an id for a work/FileSet
    it { is_expected.to be_able_to(:read, :admin_dashboard) }
    it { is_expected.to be_able_to(:manage, AdminSet) }
    it { is_expected.to be_able_to(:create, AdminSet) }
  end

  describe "AdminSets and PermissionTemplates" do
    let(:permission_template) { build(:permission_template, admin_set_id: admin_set.id) }
    let(:permission_template_access) { build(:permission_template_access, permission_template: permission_template) }
    let(:user) { create(:user) }
    let(:admin_set) { create(:admin_set) }

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
      let(:admin_set) { create(:admin_set, edit_users: [user]) }
      it '#admin? is false' do
        expect(ability).not_to be_admin
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
