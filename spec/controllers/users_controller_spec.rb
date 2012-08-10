require 'spec_helper'

describe UsersController do
  before(:all) do
    @user = FactoryGirl.find_or_create(:user)
    @another_user = FactoryGirl.find_or_create(:archivist)
    sign_in @user
  end
  describe "#show" do
    it "show the user profile if user exists" do
      get :show, uid: @user.login
      response.should be_success
      response.should_not redirect_to(root_path)
      flash[:alert].should be_empty
    end
    it "redirects to root if user does not exist" do
      get :show, uid: 'johndoe666'
      response.should redirect_to(root_path)
      flash[:alert].should include ("User 'johndoe666' does not exist")
    end
  end
  describe "#edit" do
    it "show edit form when user edits own profile" do
      get :edit, uid: @user.login
      response.should be_success
      response.should render_template('users/edit')
      flash[:alert].should be_empty
    end
    it "redirects to show profile when user attempts to edit another profile" do
      get :edit, uid: @another_user.login
      response.should redirect_to(profile_path(@another_user.login))
      flash[:alert].should include("You cannot edit jilluser's profile")
    end
  end
  describe "#update" do
    it "should not allow other users to update" do
      post :update, uid: @another_user.login, params: { user: { avatar: nil } }
      response.should redirect_to(profile_path(@another_user.login))
      flash[:alert].should include("You cannot edit jilluser's profile")
    end
    it "should set an avatar and redirect to profile" do
      @user.avatar?.should be_false
      f = fixture_file_upload('/world.png', 'image/png')
      Resque.expects(:enqueue).with(UserEditProfileEventJob, @user.login).once
      post :update, uid: @user.login, params: { user: { avatar: f } }
      response.should be_success
      response.should redirect_to(profile_path(@user.login))
      flash[:notice].should include("Your profile has been updated")
      @user.avatar?.should be_true
    end
    it "should validate the content type of an avatar" do
      f = fixture_file_upload('/image.jp2', 'image/jp2')
      Resque.expects(:enqueue).with(UserEditProfileEventJob, @user.login).never
      post :update, uid: @user.login, params: { user: { avatar: f } }
      response.should redirect_to(profile_path(@user.login))
      flash[:alert].should include("something about content type")
    end
    it "should validate the size of an avatar" do
      f = fixture_file_upload('/4-20.png', 'image/png')
      Resque.expects(:enqueue).with(UserEditProfileEventJob, @user.login).never
      post :update, uid: @user.login, params: { user: { avatar: f } }
      response.should redirect_to(profile_path(@user.login))
      flash[:alert].should include("something about file size")
    end
    it "should delete an avatar" do
      Resque.expects(:enqueue).with(UserEditProfileEventJob, @user.login).once
      post :update, uid: @user.login, params: { delete_avatar: true }
      response.should redirect_to(profile_path(@user.login))
      flash[:notice].should include("Your profile has been updated")
      @user.avatar?.should be_false
    end
    it "should refresh directory attributes"
  end
  describe "#follow" do
    it "should follow another user if not already following, and log an event" do
      @user.following?(@another_user).should be_false
      Resque.expects(:enqueue).with(UserFollowEventJob, @user.login, @another_user.login).once
      post :follow, uid: @another_user.login
      response.should be_success
      response.should redirect_to(profile_path(@another_user.login))
      flash[:notice].should include("You are following #{@another_user.login}")
    end
    it "should redirect to profile if already following and not log an event" do
      @user.stubs(:following?).with(@another_user).returns(true)
      Resque.expects(:enqueue).with(UserFollowEventJob, @user.login, @another_user.login).never
      post :follow, uid: @another_user.login
      response.should redirect_to(profile_path(@another_user.login))
      flash[:notice].should include("You are following #{@another_user.login}")
    end
    it "should redirect to profile if user attempts to self-follow and not log an event" do
      Resque.expects(:enqueue).with(UserFollowEventJob, @user.login, @user.login).never
      post :follow, uid: @user.login
      response.should redirect_to(profile_path(@user.login))
      flash[:notice].should include("You cannot follow or unfollow yourself")
    end
  end
  describe "#unfollow" do
    it "should unfollow another user if already following, and log an event" do
      @user.stubs(:following?).with(@another_user).returns(true)
      Resque.expects(:enqueue).with(UserUnfollowEventJob, @user.login, @another_user.login).once
      post :unfollow, uid: @another_user.login
      response.should be_success
      response.should redirect_to(profile_path(@another_user.login))
      flash[:notice].should include("You are no longer following #{@another_user.login}")
    end
    it "should redirect to profile if not following and not log an event" do
      @user.stubs(:following?).with(@another_user).returns(false)
      Resque.expects(:enqueue).with(UserUnfollowEventJob, @user.login, @another_user.login).never
      post :unfollow, uid: @another_user.login
      response.should redirect_to(profile_path(@another_user.login))
      flash[:notice].should include("You are no longer following #{@another_user.login}")
    end
    it "should redirect to profile if user attempts to self-follow and not log an event" do
      Resque.expects(:enqueue).with(UserUnfollowEventJob, @user.login, @user.login).never
      post :unfollow, uid: @user.login
      response.should redirect_to(profile_path(@user.login))
      flash[:notice].should include("You cannot follow or unfollow yourself")
    end
  end
end
