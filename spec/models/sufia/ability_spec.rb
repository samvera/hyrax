require 'cancan/matchers'

describe Sufia::Ability, type: :model do
  let(:ability) { Ability.new(user) }
  subject { ability }
  describe "a user with no roles" do
    let(:user) { nil }
    it { is_expected.not_to be_able_to(:create, FileSet) }
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
    it { is_expected.to be_able_to(:create, FileSet) }
    it { is_expected.not_to be_able_to(:create, TinymceAsset) }
    it { is_expected.not_to be_able_to(:create, ContentBlock) }
    it { is_expected.not_to be_able_to(:update, ContentBlock) }
    it { is_expected.to be_able_to(:read, ContentBlock) }
    it { is_expected.not_to be_able_to(:read, Sufia::Statistics) }
    it { is_expected.not_to be_able_to(:read, :admin_dashboard) }
    it { is_expected.not_to be_able_to(:create, AdminSet) }
    it { is_expected.not_to be_able_to(:update, Sufia::PermissionTemplate) }
    it { is_expected.not_to be_able_to(:destroy, Sufia::PermissionTemplateAccess) }
  end

  describe "a user in the admin group" do
    let(:user) { create(:user) }
    before { allow(user).to receive_messages(groups: ['admin', 'registered']) }
    it { is_expected.to be_able_to(:create, FileSet) }
    it { is_expected.to be_able_to(:create, TinymceAsset) }
    it { is_expected.to be_able_to(:create, ContentBlock) }
    it { is_expected.to be_able_to(:update, ContentBlock) }
    it { is_expected.to be_able_to(:read, ContentBlock) }
    it { is_expected.to be_able_to(:read, Sufia::Statistics) }
    it { is_expected.to be_able_to(:read, :admin_dashboard) }
    it { is_expected.to be_able_to(:manage, AdminSet) }
    it { is_expected.to be_able_to(:manage, Sufia::PermissionTemplate) }
    it { is_expected.to be_able_to(:manage, Sufia::PermissionTemplateAccess) }
  end

  describe "proxies and transfers" do
    let(:sender) { create(:user) }
    let(:user) { create(:user) }
    let(:work) { create(:work, user: sender) }

    it { is_expected.not_to be_able_to(:transfer, work.id) }

    describe "user_is_depositor?" do
      subject { ability.send(:user_is_depositor?, work.id) }
      it { is_expected.to be false }
    end

    context "with a ProxyDepositRequest for a work they have deposited" do
      subject { Ability.new(sender) }
      it { is_expected.to be_able_to(:transfer, work.id) }
    end

    context "with a ProxyDepositRequest that they receive" do
      let(:request) { ProxyDepositRequest.create!(work_id: work.id, receiving_user: user, sending_user: sender) }
      it { is_expected.to be_able_to(:accept, request) }
      it { is_expected.to be_able_to(:reject, request) }
      it { is_expected.not_to be_able_to(:destroy, request) }

      context "and the request has already been accepted" do
        let(:request) { ProxyDepositRequest.create!(work_id: work.id, receiving_user: user, sending_user: sender, status: 'accepted') }
        it { is_expected.not_to be_able_to(:accept, request) }
        it { is_expected.not_to be_able_to(:reject, request) }
        it { is_expected.not_to be_able_to(:destroy, request) }
      end
    end

    context "with a ProxyDepositRequest they are the sender of" do
      let(:request) { ProxyDepositRequest.create!(work_id: work.id, receiving_user: sender, sending_user: user) }
      it { is_expected.not_to be_able_to(:accept, request) }
      it { is_expected.not_to be_able_to(:reject, request) }
      it { is_expected.to be_able_to(:destroy, request) }

      context "and the request has already been accepted" do
        let(:request) { ProxyDepositRequest.create!(work_id: work.id, receiving_user: sender, sending_user: user, status: 'accepted') }
        it { is_expected.not_to be_able_to(:accept, request) }
        it { is_expected.not_to be_able_to(:reject, request) }
        it { is_expected.not_to be_able_to(:destroy, request) }
      end
    end
  end
end
