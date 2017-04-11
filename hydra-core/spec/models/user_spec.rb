require 'spec_helper'
require 'hydra/shared_spec/group_service_interface'

describe User do

  describe "#user_key" do
    let(:user) { User.new.tap {|u| u.email = "foo@example.com"} }
    before do
      allow(user).to receive(:username).and_return('foo')
    end
    subject { user.user_key }

    context "by default" do
      it "returns email" do
        expect(subject).to eq 'foo@example.com'
      end
    end

    context "when devise is configured to use the username" do
      before do
        allow(Devise).to receive(:authentication_keys).and_return([:username])
      end
      it "returns username" do
        expect(subject).to eq 'foo'
      end
    end
  end

  describe '.group_service' do
    let(:group_service) { described_class.group_service }
    it_behaves_like 'a Hydra group_service interface'
  end

  describe "#groups" do
    let(:user) { FactoryGirl.create(:user) }
    let(:mock_service) { double }
    before do
      user.group_service = mock_service
    end
    subject { user.groups }
    it "returns a list of groups" do
      expect(mock_service).to receive(:fetch_groups).with(user: user).and_return(['my_group'])
      expect(subject).to eq ['my_group']
    end
  end
end
