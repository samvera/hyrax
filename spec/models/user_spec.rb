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
    pending "Move to scholarsphere"
    @user.login.should == "jilluser"
  end
  it "should have an email" do
    @user.user_key.should == "jilluser@example.com"
  end
  it "should have activity stream-related methods defined" do
    @user.should respond_to(:stream)
    @user.should respond_to(:events)
    @user.should respond_to(:profile_events)
    @user.should respond_to(:create_event)
    @user.should respond_to(:log_event)
    @user.should respond_to(:log_profile_event)
  end
  it "should have social attributes" do
    @user.should respond_to(:twitter_handle)
    @user.should respond_to(:facebook_handle)
    @user.should respond_to(:googleplus_handle)
  end
  it "should redefine to_param to make redis keys more recognizable (and useable within Rails URLs)" do
    @user.to_param.should == "jilluser@example-dot-com"
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
end
