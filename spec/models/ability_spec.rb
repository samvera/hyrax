require 'spec_helper'
require 'cancan/matchers'

describe Sufia::Ability do
  describe "a user with no roles" do
    let(:user) { nil }
    subject { Ability.new(user) }
    it { should_not be_able_to(:create, GenericFile) }
    it { should_not be_able_to(:create, TinymceAsset) }
    it { should_not be_able_to(:update, ContentBlock) }
  end

  describe "a registered user" do
    let(:user) { FactoryGirl.find_or_create(:archivist) }
    subject { Ability.new(user) }
    it { should be_able_to(:create, GenericFile) }
    it { should_not be_able_to(:create, TinymceAsset) }
    it { should_not be_able_to(:update, ContentBlock) }
  end

  describe "a user in the admin group" do
    let(:user) { FactoryGirl.find_or_create(:archivist) }
    before { user.stub(groups: ['admin', 'registered']) }
    subject { Ability.new(user) }
    it { should be_able_to(:create, GenericFile) }
    it { should be_able_to(:create, TinymceAsset) }
    it { should be_able_to(:update, ContentBlock) }
  end

  describe "proxies and transfers" do
    let(:sender) { FactoryGirl.find_or_create(:jill) }
    let(:user) { FactoryGirl.find_or_create(:archivist) }
    let(:file) do
      GenericFile.new.tap do|file|
        file.apply_depositor_metadata(sender.user_key)
        file.save!
      end
    end
    subject { Ability.new(user) }
    it { should_not be_able_to(:transfer, file.pid) }

    context "with a ProxyDepositRequest for a file they have deposited" do
      subject { Ability.new(sender) }
      it { should be_able_to(:transfer, file.pid) }
    end

    context "with a ProxyDepositRequest that they receive" do
      let(:request) { ProxyDepositRequest.create!(pid: file.pid, receiving_user: user, sending_user: sender) }
      it { should be_able_to(:accept, request) }
      it { should be_able_to(:reject, request) }
      it { should_not be_able_to(:destroy, request) }

      context "and the request has already been accepted" do
        let(:request) { ProxyDepositRequest.create!(pid: file.pid, receiving_user: user, sending_user: sender, status: 'accepted') }
        it { should_not be_able_to(:accept, request) }
        it { should_not be_able_to(:reject, request) }
        it { should_not be_able_to(:destroy, request) }
      end
    end

    context "with a ProxyDepositRequest they are the sender of" do
      let(:request) { ProxyDepositRequest.create!(pid: file.pid, receiving_user: sender, sending_user: user) }
      it { should_not be_able_to(:accept, request) }
      it { should_not be_able_to(:reject, request) }
      it { should be_able_to(:destroy, request) }

      context "and the request has already been accepted" do
        let(:request) { ProxyDepositRequest.create!(pid: file.pid, receiving_user: sender, sending_user: user, status: 'accepted') }
        it { should_not be_able_to(:accept, request) }
        it { should_not be_able_to(:reject, request) }
        it { should_not be_able_to(:destroy, request) }
      end
    end
  end
end
