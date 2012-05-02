require 'spec_helper'

describe User do
  before do
    @user = User.create(:email => "testuser@example.com", 
                        :login => "testuser")
  end
  after do
    @user.delete
  end
  it "should have a login and email" do
    @user.login.should == "testuser"
    @user.email.should == "testuser@example.com"
  end

  describe "#groups" do
    before do
      @user = FactoryGirl.create(:user)
      Dil::LDAP.expects(:groups_for_user).with(@user.login+',dc=psu,dc=edu').returns(["umg/up.dlt.gamma-ci", "umg/up.dlt.redmine"])
    end
    it "should return a list" do
      @user.groups.should == ["umg/up.dlt.gamma-ci", "umg/up.dlt.redmine"]
    end
  end
  
end
