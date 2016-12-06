require 'spec_helper'
require 'cancan/matchers'

describe 'Proxy and Transfer Abilities' do
  subject { ability }
  let(:ability) { Ability.new(user) }
  let(:user) { create(:user) }

  describe "Transfers" do
    before do
      allow(Flipflop).to receive(:transfer_works?).and_return(enabled)
      allow(ability).to receive(:user_is_depositor?).with('777').and_return(mine)
    end
    let(:work_id) { '777' }

    describe "when transfers are enabled" do
      let(:enabled) { true }

      context "a work belonging to someone else" do
        let(:mine) { false }
        it { is_expected.not_to be_able_to(:transfer, work_id) }
      end

      context "my own work" do
        let(:mine) { true }
        it { is_expected.to be_able_to(:transfer, work_id) }
      end
    end

    describe "when transfers are disabled" do
      let(:enabled) { false }

      let(:mine) { true }
      it { is_expected.not_to be_able_to(:transfer, work_id) }
    end
  end

  describe "#user_is_depositor?" do
    let(:work) { create(:work) }
    subject { ability.send(:user_is_depositor?, work.id) }
    it { is_expected.to be false }
  end

  describe "ProxyDepositRequests" do
    let(:sender) { create(:user) }
    let(:work) { create(:work, user: sender) }

    context "creating a ProxyDepositRequest" do
      before do
        allow(Flipflop).to receive(:proxy_deposit?).and_return(enabled)
      end
      describe "when proxy deposit is enabled" do
        let(:enabled) { true }

        context "for a registered user" do
          it { is_expected.to be_able_to(:create, ProxyDepositRequest) }
        end
        context "for a guest user" do
          let(:user) { create(:user, :guest) }
          it { is_expected.not_to be_able_to(:create, ProxyDepositRequest) }
        end
      end

      context "when disabled" do
        let(:enabled) { false }
        it { is_expected.not_to be_able_to(:create, ProxyDepositRequest) }
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
