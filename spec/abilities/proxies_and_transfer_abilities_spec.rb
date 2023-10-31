# frozen_string_literal: true
require 'cancan/matchers'

RSpec.describe Hyrax::Ability do
  subject(:ability) { Ability.new(user) }
  let(:user) { create(:user) }

  describe "Transfers" do
    before do
      allow(Flipflop).to receive(:transfer_works?).and_return(transfer_enabled)
      allow(ability).to receive(:user_is_depositor?).with('777').and_return(mine) # rubocop:disable RSpec/SubjectStub
      allow(Flipflop).to receive(:proxy_deposit?).and_return(proxy_enabled)
    end
    let(:work_id) { '777' }

    describe "when transfers are enabled and proxies are enabled" do
      let(:transfer_enabled) { true }
      let(:proxy_enabled) { true }

      context "a work belonging to someone else" do
        let(:mine) { false }

        it { is_expected.not_to be_able_to(:transfer, work_id) }
      end

      context "my own work" do
        let(:mine) { true }

        it { is_expected.to be_able_to(:transfer, work_id) }
      end
    end

    describe "when transfers are enabled and proxies are disabled" do
      let(:transfer_enabled) { true }
      let(:proxy_enabled) { false }

      context "a work belonging to someone else" do
        let(:mine) { false }

        it { is_expected.not_to be_able_to(:transfer, work_id) }
      end

      context "my own work" do
        let(:mine) { true }

        it { is_expected.to be_able_to(:transfer, work_id) }
      end
    end

    describe "when transfers are disabled and proxy is enabled" do
      let(:transfer_enabled) { false }
      let(:proxy_enabled) { true }

      let(:mine) { true }

      it { is_expected.not_to be_able_to(:transfer, work_id) }
    end

    describe "when transfers are disabled and proxy is disabled" do
      let(:transfer_enabled) { false }
      let(:proxy_enabled) { false }

      let(:mine) { true }

      it { is_expected.not_to be_able_to(:transfer, work_id) }
    end
  end

  describe "#user_is_depositor?" do
    let(:work) { valkyrie_create(:hyrax_work) }

    subject { ability.send(:user_is_depositor?, work.id) }

    it { is_expected.to be false }
  end

  describe "ProxyDepositRequests" do
    let(:sender) { create(:user) }
    let(:work) { valkyrie_create(:hyrax_work, depositor: sender.user_key, edit_users: [sender]) }

    context "creating a ProxyDepositRequest" do
      before do
        allow(Flipflop).to receive(:proxy_deposit?).and_return(proxy_enabled)
        allow(Flipflop).to receive(:transfer_works?).and_return(transfer_enabled)
      end

      describe "when proxy deposit is enabled and transfer is disabled" do
        let(:proxy_enabled) { true }
        let(:transfer_enabled) { false }

        context "for a registered user" do
          it { is_expected.to be_able_to(:create, ProxyDepositRequest) }
        end
        context "for a guest user" do
          let(:user) { create(:user, :guest) }

          it { is_expected.not_to be_able_to(:create, ProxyDepositRequest) }
        end
      end

      context "when proxy is disabled and trasfer is disabled" do
        let(:proxy_enabled) { false }
        let(:transfer_enabled) { false }

        it { is_expected.not_to be_able_to(:create, ProxyDepositRequest) }
      end

      context "when proxy is disabled and trasfer is enabled" do
        let(:proxy_enabled) { false }
        let(:transfer_enabled) { true }

        it { is_expected.to be_able_to(:create, ProxyDepositRequest) }
      end
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
