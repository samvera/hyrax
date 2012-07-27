require 'spec_helper'

describe User do
  before do
    @user = FactoryGirl.find_or_create(:user)
  end
  after do
    @user.delete
  end
  it "should have a login" do
    @user.login.should == "jilluser"
  end

  describe "#groups" do
    before do
      filter = Net::LDAP::Filter.eq('uid', @user.login)
      Hydra::LDAP.expects(:groups_for_user).with(filter).returns(["umg/up.dlt.gamma-ci", "umg/up.dlt.redmine"])
    end
    it "should return a list" do
      @user.groups.should == ["umg/up.dlt.gamma-ci", "umg/up.dlt.redmine"]
    end
  end
end
