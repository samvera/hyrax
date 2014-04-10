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
    let(:user) { FactoryGirl.create(:user) }
    subject { Ability.new(user) }
    it { should be_able_to(:create, GenericFile) }
    it { should_not be_able_to(:create, TinymceAsset) }
    it { should_not be_able_to(:update, ContentBlock) }
  end

  describe "a user in the admin group" do
    let(:user) { FactoryGirl.create(:user) }
    before { user.stub(groups: ['admin', 'registered']) }
    subject { Ability.new(user) }
    it { should be_able_to(:create, GenericFile) }
    it { should be_able_to(:create, TinymceAsset) }
    it { should be_able_to(:update, ContentBlock) }
  end
end
