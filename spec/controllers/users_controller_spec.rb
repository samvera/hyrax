require 'spec_helper'

describe UsersController do
  before(:each) do
    @user = FactoryGirl.find_or_create(:jill)
    @another_user = FactoryGirl.find_or_create(:archivist)
    sign_in @user
    User.any_instance.stub(:groups).and_return([])
    controller.stub(:clear_session_user) ## Don't clear out the authenticated session
  end

  describe "#show" do
    it "show the user profile if user exists" do
      get :show, id: @user.user_key
      response.should be_success
      response.should_not redirect_to(root_path)
      flash[:alert].should be_nil
    end
    it "redirects to root if user does not exist" do
      get :show, id: 'johndoe666'
      response.should redirect_to(root_path)
      flash[:alert].should include ("User 'johndoe666' does not exist")
    end

    describe "when the user has trophies" do
      let(:user) { @user } 
      let(:file1) { GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save! } } 
      let(:file2) { GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save! } } 
      let(:file3) { GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save! } } 
      let!(:trophy1) { user.trophies.create!(generic_file_id: file1.noid) }
      let!(:trophy2) { user.trophies.create!(generic_file_id: file2.noid) }
      let!(:trophy3) { user.trophies.create!(generic_file_id: file3.noid) }

      it "show the user profile if user exists" do
        get :show, id: user.user_key
        response.should be_success
        assigns[:trophies].should match_array([file1, file2, file3])
      end

    end
  end
  describe "#index" do
    before do
      @u1 = FactoryGirl.find_or_create(:archivist)
      @u2 = FactoryGirl.find_or_create(:curator)
    end
    describe "requesting html" do
      it "should test users" do
        get :index
        assigns[:users].should include(@u1, @u2)
        response.should be_successful
      end
    end
    describe "requesting json" do
      it "should display users" do
        get :index, format: :json
        response.should be_successful
        json = JSON.parse(response.body)
        json.map{|u| u['id']}.should include(@u1.email, @u2.email)
        json.map{|u| u['text']}.should include(@u1.email, @u2.email)
      end
    end
    describe "query users"  do
      it "finds the expected user via email" do
        get :index,  uq: @u1.email
        assigns[:users].should include(@u1)
        assigns[:users].should_not include(@u2)
        response.should be_successful
      end
      it "finds the expected user via display name" do
        @u1.display_name = "Dr. Curator"
        @u1.save
        @u2.display_name = "Jr. Architect"
        @u2.save
        User.any_instance.stub(:display_name).and_return("Dr. Curator", "Jr.Archivist")
        get :index,  uq: @u1.display_name
        assigns[:users].should include(@u1)
        assigns[:users].should_not include(@u2)
        response.should be_successful
        @u1.display_name = nil
        @u1.save
        @u2.display_name = nil
        @u2.save
      end
      it "uses the base query" do
        u3 = FactoryGirl.find_or_create(:jill)
        controller.stub(:base_query).and_return(['email == "jilluser@example.com"'])
        get :index
        assigns[:users].should include(u3)
        assigns[:users].should_not include(@u1, @u2)
        u3.destroy
      end
    end
  end
  describe "#edit" do
    it "show edit form when user edits own profile" do
      get :edit, id: @user.user_key
      response.should be_success
      response.should render_template('users/edit')
      flash[:alert].should be_nil
    end
    it "redirects to show profile when user attempts to edit another profile" do
      get :edit, id: @another_user.user_key
      response.should redirect_to(@routes.url_helpers.profile_path(@another_user.to_param))
      flash[:alert].should include("Permission denied: cannot access this page.")
    end
    describe "when the user has trophies" do
      let(:user) { @user } 
      let(:file1) { GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save! } } 
      let(:file2) { GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save! } } 
      let(:file3) { GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save! } } 
      let!(:trophy1) { user.trophies.create!(generic_file_id: file1.noid) }
      let!(:trophy2) { user.trophies.create!(generic_file_id: file2.noid) }
      let!(:trophy3) { user.trophies.create!(generic_file_id: file3.noid) }

      it "show the user profile if user exists" do
        get :edit, id: @user.user_key
        response.should be_success
        assigns[:trophies].should match_array([file1, file2, file3])
      end

    end
  end
  describe "#update" do
    it "should not allow other users to update" do
      post :update, id: @another_user.user_key, user: { avatar: nil }
      response.should redirect_to(@routes.url_helpers.profile_path(@another_user.to_param))
      flash[:alert].should include("Permission denied: cannot access this page.")
    end
    it "should set an avatar and redirect to profile" do
      expect(@user.avatar?).to be false
      s1 = double('one')
      UserEditProfileEventJob.should_receive(:new).with(@user.user_key).and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once
      f = fixture_file_upload('/world.png', 'image/png')
      post :update, id: @user.user_key, user: { avatar: f }
      response.should redirect_to(@routes.url_helpers.profile_path(@user.to_param))
      flash[:notice].should include("Your profile has been updated")
      expect(User.find_by_user_key(@user.user_key).avatar?).to be true
    end
    it "should validate the content type of an avatar" do
      Sufia.queue.should_receive(:push).never
      f = fixture_file_upload('/image.jp2', 'image/jp2')
      post :update, id: @user.user_key, user: { avatar: f }
      response.should redirect_to(@routes.url_helpers.edit_profile_path(@user.to_param))
      flash[:alert].should include("Avatar You are not allowed to upload \"jp2\" files, allowed types: jpg, jpeg, png, gif, bmp, tif, tiff")
    end
    it "should validate the size of an avatar" do
      f = fixture_file_upload('/4-20.png', 'image/png')
      Sufia.queue.should_receive(:push).never
      post :update, id: @user.user_key, user: { avatar: f }
      response.should redirect_to(@routes.url_helpers.edit_profile_path(@user.to_param))
      flash[:alert].should include("Avatar file size must be less than 2MB")
    end
    context "user with existing avatar" do
      before do
        f = fixture_file_upload('/world.png', 'image/png')
        @user.avatar = f
        @user.save
      end
      it "should delete an avatar" do
        s1 = double('one')
        UserEditProfileEventJob.should_receive(:new).with(@user.user_key).and_return(s1)
        Sufia.queue.should_receive(:push).with(s1).once
        post :update, id: @user.user_key, delete_avatar: true
        response.should redirect_to(@routes.url_helpers.profile_path(@user.to_param))
        flash[:notice].should include("Your profile has been updated")
        expect(User.find_by_user_key(@user.user_key).avatar?).to be false
      end
    end
    it "should refresh directory attributes" do
      s1 = double('one')
      UserEditProfileEventJob.should_receive(:new).with(@user.user_key).and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once
      User.any_instance.should_receive(:populate_attributes).once
      post :update, id: @user.user_key, update_directory: true
      response.should redirect_to(@routes.url_helpers.profile_path(@user.to_param))
      flash[:notice].should include("Your profile has been updated")
    end
    it "should set an social handles" do
      expect(@user.twitter_handle).to be_blank
      expect(@user.facebook_handle).to be_blank
      expect(@user.googleplus_handle).to be_blank
      expect(@user.linkedin_handle).to be_blank
      post :update, id: @user.user_key, user: { twitter_handle: 'twit', facebook_handle: 'face', googleplus_handle: 'goo', linkedin_handle:"link" }
      response.should redirect_to(@routes.url_helpers.profile_path(@user.to_param))
      flash[:notice].should include("Your profile has been updated")
      u = User.find_by_user_key(@user.user_key)
      u.twitter_handle.should == 'twit'
      u.facebook_handle.should == 'face'
      u.googleplus_handle.should == 'goo'
      u.linkedin_handle.should == 'link'
    end

    context "when removing a trophy" do
      let(:user) { @user }
      let(:file) { GenericFile.new.tap { |f| f.apply_depositor_metadata(user); f.save! } } 
      before do
        user.trophies.create!(generic_file_id: file.noid)
      end
      it "should remove a trophy" do
        expect {
          post :update, id: user.user_key,  'remove_trophy_'+file.noid => 'yes'
        }.to change { user.trophies.count }.by(-1)
        response.should redirect_to(@routes.url_helpers.profile_path(user.to_param))
        flash[:notice].should include("Your profile has been updated")
      end
    end
  end

  describe "#follow" do
    after(:all) do
      @user.unfollow(@another_user) rescue nil
    end
    it "should follow another user if not already following, and log an event" do
      expect(@user.following?(@another_user)).to be false
      s1 = double('one')
      UserFollowEventJob.should_receive(:new).with(@user.user_key, @another_user.user_key).and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once
      post :follow, id: @another_user.user_key
      response.should redirect_to(@routes.url_helpers.profile_path(@another_user.to_param))
      flash[:notice].should include("You are following #{@another_user.user_key}")
    end
    it "should redirect to profile if already following and not log an event" do
      User.any_instance.stub(:following?).with(@another_user).and_return(true)
      #Resque.should_receive(:enqueue).with(UserFollowEventJob, @user.user_key, @another_user.user_key).never
      Sufia.queue.should_receive(:push).never
      post :follow, id: @another_user.user_key
      response.should redirect_to(@routes.url_helpers.profile_path(@another_user.to_param))
      flash[:notice].should include("You are following #{@another_user.user_key}")
    end
    it "should redirect to profile if user attempts to self-follow and not log an event" do
      #Resque.should_receive(:enqueue).with(UserFollowEventJob, @user.user_key, @user.user_key).never
      Sufia.queue.should_receive(:push).never
      post :follow, id: @user.user_key
      response.should redirect_to(@routes.url_helpers.profile_path(@user.to_param))
      flash[:alert].should include("You cannot follow or unfollow yourself")
    end
  end
  describe "#unfollow" do
    it "should unfollow another user if already following, and log an event" do
      User.any_instance.stub(:following?).with(@another_user).and_return(true)
      s1 = double('one')
      UserUnfollowEventJob.should_receive(:new).with(@user.user_key, @another_user.user_key).and_return(s1)
      Sufia.queue.should_receive(:push).with(s1).once
      post :unfollow, id: @another_user.user_key
      response.should redirect_to(@routes.url_helpers.profile_path(@another_user.to_param))
      flash[:notice].should include("You are no longer following #{@another_user.user_key}")
    end
    it "should redirect to profile if not following and not log an event" do
      @user.stub(:following?).with(@another_user).and_return(false)
      #Resque.should_receive(:enqueue).with(UserUnfollowEventJob, @user.user_key, @another_user.user_key).never
      Sufia.queue.should_receive(:push).never
      post :unfollow, id: @another_user.user_key
      response.should redirect_to(@routes.url_helpers.profile_path(@another_user.to_param))
      flash[:notice].should include("You are no longer following #{@another_user.user_key}")
    end
    it "should redirect to profile if user attempts to self-follow and not log an event" do
      #Resque.should_receive(:enqueue).with(UserUnfollowEventJob, @user.user_key, @user.user_key).never
      Sufia.queue.should_receive(:push).never
      post :unfollow, id: @user.user_key
      response.should redirect_to(@routes.url_helpers.profile_path(@user.to_param))
      flash[:alert].should include("You cannot follow or unfollow yourself")
    end
  end
  describe "#toggle_trophy" do
     before do
       @file = GenericFile.new()
       @file.apply_depositor_metadata(@user)
       @file.save
       @file_id = @file.pid.split(":").last
     end
     after do
       @file.delete
     end
     it "should trophy a file" do
      post :toggle_trophy, {id: @user.user_key, file_id: @file_id}
      JSON.parse(response.body)['user_id'].should == @user.id
      JSON.parse(response.body)['generic_file_id'].should == @file_id
    end
     it "should not trophy a file for a different user" do
      post :toggle_trophy, {id: @another_user.user_key, file_id: @file_id}
      response.should_not be_success
    end
     it "should not trophy a file with no edit privs" do
      sign_out @user
      sign_in @another_user
      post :toggle_trophy, {id: @another_user.user_key, file_id: @file_id}
      response.should_not be_success
    end
  end
end
