describe UsersController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }
  before(:each) do
    sign_in user
    allow_any_instance_of(User).to receive(:groups).and_return([])
    allow(controller).to receive(:clear_session_user) ## Don't clear out the authenticated session
  end

  describe "#show" do
    it "show the user profile if user exists" do
      get :show, id: user.user_key
      expect(response).to be_success
      expect(response).to_not redirect_to(root_path)
      expect(flash[:alert]).to be_nil
    end
    it "redirects to root if user does not exist" do
      get :show, id: 'johndoe666'
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("User 'johndoe666' does not exist")
    end

    describe "when the user has trophies" do
      let(:work1) { GenericWork.create(title: ["w1"]) { |w| w.apply_depositor_metadata(user) } }
      let(:work2) { GenericWork.create(title: ["w2"]) { |w| w.apply_depositor_metadata(user) } }
      let(:work3) { GenericWork.create(title: ["w3"]) { |w| w.apply_depositor_metadata(user) } }
      let!(:trophy1) { user.trophies.create!(work_id: work1.id) }
      let!(:trophy2) { user.trophies.create!(work_id: work2.id) }
      let!(:trophy3) { user.trophies.create!(work_id: work3.id) }
      let!(:badtrophy) { user.trophies.create!(work_id: 'not_a_generic_work') }

      it "show the user profile if user exists" do
        get :show, id: user.user_key
        expect(response).to be_success
        expect(assigns[:trophies]).to match_array([work1, work2, work3])
      end
    end
  end
  describe "#index" do
    let!(:u1) { FactoryGirl.create(:user) }
    let!(:u2) { FactoryGirl.create(:user) }

    describe "requesting html" do
      it "tests users" do
        get :index
        expect(assigns[:users]).to include(u1, u2)
        expect(response).to be_successful
      end
    end
    describe "requesting json" do
      it "displays users" do
        get :index, format: :json
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json.map { |u| u['id'] }).to include(u1.email, u2.email)
        expect(json.map { |u| u['text'] }).to include(u1.email, u2.email)
      end
    end

    describe "query users" do
      it "finds the expected user via email" do
        get :index, uq: u1.email
        expect(assigns[:users]).to include(u1)
        expect(assigns[:users]).to_not include(u2)
        expect(response).to be_successful
      end

      it "finds the expected user via display name" do
        u1.display_name = "Dr. Curator"
        u1.save
        u2.display_name = "Jr. Architect"
        u2.save
        allow_any_instance_of(User).to receive(:display_name).and_return("Dr. Curator", "Jr.Archivist")
        get :index, uq: u1.display_name
        expect(assigns[:users]).to include(u1)
        expect(assigns[:users]).to_not include(u2)
        expect(response).to be_successful
        u1.display_name = nil
        u1.save
        u2.display_name = nil
        u2.save
      end

      it "uses the base query" do
        u3 = FactoryGirl.create(:user)
        allow(controller).to receive(:base_query).and_return(["email == \"#{u3.email}\""])
        get :index
        expect(assigns[:users]).to include(u3)
        expect(assigns[:users]).to_not include(u1, u2)
        u3.destroy
      end
    end
  end

  describe "#edit" do
    it "show edit form when user edits own profile" do
      get :edit, id: user.user_key
      expect(response).to be_success
      expect(response).to render_template('users/edit')
      expect(flash[:alert]).to be_nil
    end

    context "when user attempts to edit another profile" do
      let(:another_user) { FactoryGirl.create(:user) }
      context 'with default abilities' do
        it "redirects to show profile" do
          expect_any_instance_of(Ability).to receive(:can?).with(:edit, another_user).and_return(false)
          get :edit, id: another_user.to_param
          expect(response).to redirect_to(@routes.url_helpers.profile_path(another_user.to_param))
          expect(flash[:alert]).to include("Permission denied: cannot access this page.")
        end
      end
      context 'with a custom ability' do
        before do
          allow_any_instance_of(Ability).to receive(:can?).with(:edit, another_user).and_return(true)
        end
        it "allows user to edit another user's profile" do
          get :edit, id: another_user.to_param
          expect(response).to be_success
          expect(response).not_to redirect_to(@routes.url_helpers.profile_path(another_user.to_param))
          expect(flash[:alert]).to be_nil
        end
      end
    end

    context "when the user has trophies" do
      let(:work1) { GenericWork.create(title: ["w1"]) { |w| w.apply_depositor_metadata(user) } }
      let(:work2) { GenericWork.create(title: ["w2"]) { |w| w.apply_depositor_metadata(user) } }
      let(:work3) { GenericWork.create(title: ["w3"]) { |w| w.apply_depositor_metadata(user) } }
      let!(:trophy1) { user.trophies.create!(work_id: work1.id) }
      let!(:trophy2) { user.trophies.create!(work_id: work2.id) }
      let!(:trophy3) { user.trophies.create!(work_id: work3.id) }

      it "show the user profile if user exists" do
        get :edit, id: user.user_key
        expect(response).to be_success
        expect(assigns[:trophies]).to match_array([work1, work2, work3])
      end
    end
  end

  describe "#update" do
    context "the profile of another user" do
      let(:another_user) { FactoryGirl.create(:user) }
      it "does not allow other users to update" do
        post :update, id: another_user.user_key, user: { avatar: nil }
        expect(response).to redirect_to(@routes.url_helpers.profile_path(another_user.to_param))
        expect(flash[:alert]).to include("Permission denied: cannot access this page.")
      end
    end

    it "sets an avatar and redirect to profile" do
      expect(user.avatar?).to be false
      expect(UserEditProfileEventJob).to receive(:perform_later).with(user)
      f = fixture_file_upload('/1.5mb-avatar.jpg', 'image/jpg')
      post :update, id: user.user_key, user: { avatar: f }
      expect(response).to redirect_to(@routes.url_helpers.profile_path(user.to_param))
      expect(flash[:notice]).to include("Your profile has been updated")
      expect(User.find_by_user_key(user.user_key).avatar?).to be true
    end
    it "validates the content type of an avatar" do
      expect(UserEditProfileEventJob).to receive(:perform_later).never
      f = fixture_file_upload('/image.jp2', 'image/jp2')
      post :update, id: user.user_key, user: { avatar: f }
      expect(response).to redirect_to(@routes.url_helpers.edit_profile_path(user.to_param))
      expect(flash[:alert]).to include("Avatar You are not allowed to upload \"jp2\" files, allowed types: jpg, jpeg, png, gif, bmp, tif, tiff")
    end
    it "validates the size of an avatar" do
      f = fixture_file_upload('/4-20.png', 'image/png')
      expect(UserEditProfileEventJob).to receive(:perform_later).never
      post :update, id: user.user_key, user: { avatar: f }
      expect(response).to redirect_to(@routes.url_helpers.edit_profile_path(user.to_param))
      expect(flash[:alert]).to include("Avatar file size must be less than 2MB")
    end

    context "user with existing avatar" do
      before do
        f = fixture_file_upload('/world.png', 'image/png')
        user.update(avatar: f)
      end

      it "deletes an avatar" do
        expect(UserEditProfileEventJob).to receive(:perform_later).with(user)
        post :update, id: user.user_key, user: { remove_avatar: 'true' }
        expect(response).to redirect_to(@routes.url_helpers.profile_path(user.to_param))
        expect(flash[:notice]).to include("Your profile has been updated")
        expect(User.find_by_user_key(user.user_key).avatar?).to be false
      end
    end

    it "refreshes directory attributes" do
      expect(UserEditProfileEventJob).to receive(:perform_later).with(user)
      expect_any_instance_of(User).to receive(:populate_attributes).once
      post :update, id: user.user_key, user: { update_directory: 'true' }
      expect(response).to redirect_to(@routes.url_helpers.profile_path(user.to_param))
      expect(flash[:notice]).to include("Your profile has been updated")
    end

    it "sets an social handles" do
      expect(user.twitter_handle).to be_blank
      expect(user.facebook_handle).to be_blank
      expect(user.googleplus_handle).to be_blank
      expect(user.linkedin_handle).to be_blank
      expect(user.orcid).to be_blank
      post :update, id: user.user_key, user: { twitter_handle: 'twit', facebook_handle: 'face', googleplus_handle: 'goo', linkedin_handle: "link", orcid: '0000-0000-1111-2222' }
      expect(response).to redirect_to(@routes.url_helpers.profile_path(user.to_param))
      expect(flash[:notice]).to include("Your profile has been updated")
      u = User.find_by_user_key(user.user_key)
      expect(u.twitter_handle).to eq 'twit'
      expect(u.facebook_handle).to eq 'face'
      expect(u.googleplus_handle).to eq 'goo'
      expect(u.linkedin_handle).to eq 'link'
      expect(u.orcid).to eq 'http://orcid.org/0000-0000-1111-2222'
    end

    it 'displays a flash when invalid ORCID is entered' do
      expect(user.orcid).to be_blank
      post :update, id: user.user_key, user: { orcid: 'foobar' }
      expect(response).to redirect_to(@routes.url_helpers.edit_profile_path(user.to_param))
      expect(flash[:alert]).to include('Orcid must be a string of 19 characters, e.g., "0000-0000-0000-0000"')
    end

    context "when removing a trophy" do
      let(:work) { GenericWork.create(title: ["w1"]) { |w| w.apply_depositor_metadata(user) } }
      before do
        user.trophies.create!(work_id: work.id)
      end
      it "removes a trophy" do
        expect {
          post :update, id: user.user_key, 'remove_trophy_' + work.id => 'yes'
        }.to change { user.trophies.count }.by(-1)
        expect(response).to redirect_to(@routes.url_helpers.profile_path(user.to_param))
        expect(flash[:notice]).to include("Your profile has been updated")
      end
    end
  end

  describe "#follow" do
    let(:another_user) { FactoryGirl.create(:user) }
    it "follows another user if not already following, and log an event" do
      expect(user.following?(another_user)).to be false
      expect(UserFollowEventJob).to receive(:perform_later).with(user, another_user)
      post :follow, id: another_user.user_key
      expect(response).to redirect_to(@routes.url_helpers.profile_path(another_user.to_param))
      expect(flash[:notice]).to include("You are following #{another_user.user_key}")
    end
    it "redirects to profile if already following and not log an event" do
      allow_any_instance_of(User).to receive(:following?).with(another_user).and_return(true)
      expect(UserFollowEventJob).to receive(:perform_later).never
      post :follow, id: another_user.user_key
      expect(response).to redirect_to(@routes.url_helpers.profile_path(another_user.to_param))
      expect(flash[:notice]).to include("You are following #{another_user.user_key}")
    end
    it "redirects to profile if user attempts to self-follow and not log an event" do
      expect(UserFollowEventJob).to receive(:perform_later).never
      post :follow, id: user.user_key
      expect(response).to redirect_to(@routes.url_helpers.profile_path(user.to_param))
      expect(flash[:alert]).to include("You cannot follow or unfollow yourself")
    end
  end

  describe "#unfollow" do
    let(:another_user) { FactoryGirl.create(:user) }
    it "unfollows another user if already following, and log an event" do
      allow_any_instance_of(User).to receive(:following?).with(another_user).and_return(true)
      expect(UserUnfollowEventJob).to receive(:perform_later).with(user, another_user).once
      post :unfollow, id: another_user.user_key
      expect(response).to redirect_to(@routes.url_helpers.profile_path(another_user.to_param))
      expect(flash[:notice]).to include("You are no longer following #{another_user.user_key}")
    end
    it "redirects to profile if not following and not log an event" do
      allow(user).to receive(:following?).with(another_user).and_return(false)
      expect(UserUnfollowEventJob).to receive(:perform_later).never
      post :unfollow, id: another_user.user_key
      expect(response).to redirect_to(@routes.url_helpers.profile_path(another_user.to_param))
      expect(flash[:notice]).to include("You are no longer following #{another_user.user_key}")
    end
    it "redirects to profile if user attempts to self-follow and not log an event" do
      expect(UserUnfollowEventJob).to receive(:perform_later).never
      post :unfollow, id: user.user_key
      expect(response).to redirect_to(@routes.url_helpers.profile_path(user.to_param))
      expect(flash[:alert]).to include("You cannot follow or unfollow yourself")
    end
  end

  describe "#toggle_trophy" do
    let(:work) { GenericWork.create(title: ["w1"]) { |w| w.apply_depositor_metadata(user) } }
    let(:work_id) { work.id }
    let(:another_user) { FactoryGirl.create(:user) }

    it "trophies a work" do
      post :toggle_trophy, id: user.user_key, work_id: work_id
      json = JSON.parse(response.body)
      expect(json['user_id']).to eq user.id
      expect(json['work_id']).to eq work_id
    end
    it "does not trophy a work for a different user" do
      post :toggle_trophy, id: another_user.user_key, work_id: work_id
      expect(response).to_not be_success
    end
    it "does not trophy a work with no edit privs" do
      sign_in another_user
      post :toggle_trophy, id: another_user.user_key, work_id: work_id
      expect(response).to_not be_success
    end
  end
end
