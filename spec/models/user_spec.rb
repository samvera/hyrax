require 'spec_helper'

describe User do
  before(:all) do
    @user = FactoryGirl.find_or_create(:user)
    @another_user = FactoryGirl.find_or_create(:archivist)
  end
  after(:all) do
    @user.delete
    @another_user.delete
  end
  it "should have a login" do
    @user.login.should == "jilluser"
  end
  it "should have activity stream-related methods defined" do
    @user.should respond_to(:stream)
    @user.should respond_to(:events)
    @user.should respond_to(:profile_events)
    @user.should respond_to(:create_event)
    @user.should respond_to(:log_event)
    @user.should respond_to(:log_profile_event)
  end
  it "should redefine to_param to make redis keys more recognizable" do
    @user.to_param.should == @user.login
  end
  it "should have a cancan ability defined" do
    @user.should respond_to(:can?)
  end
  it "should not have any followers" do
    @user.followers_count.should == 0
    @another_user.follow_count.should == 0
  end
  describe "follow/unfollow" do
    before(:all) do
      @user = FactoryGirl.find_or_create(:user)
      @another_user = FactoryGirl.find_or_create(:archivist)
      @user.follow(@another_user)
    end
    after do
      @user.delete
      @another_user.delete
    end
    it "should be able to follow another user" do
      @user.following?(@another_user).should be_true
      @another_user.following?(@user).should be_false
      @another_user.followed_by?(@user).should be_true
      @user.followed_by?(@another_user).should be_false
    end
    it "should be able to unfollow another user" do
      @user.stop_following(@another_user)
      @user.following?(@another_user).should be_false
      @another_user.followed_by?(@user).should be_false
    end
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

  describe "#attributes" do
    before do
      entry = Net::LDAP::Entry.new()
      entry['dn'] = ["uid=mjg36,dc=psu,edu"]
      entry['cn'] = ["MICHAEL JOSEPH GIARLO"]
      Hydra::LDAP.expects(:get_user).returns([entry])
    end
    it "should return user attributes from LDAP" do
      User.directory_attributes('mjg36', ['cn']).first['cn'].should == ['MICHAEL JOSEPH GIARLO']
    end
  end
end
