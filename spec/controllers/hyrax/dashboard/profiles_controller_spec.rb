# frozen_string_literal: true
RSpec.describe Hyrax::Dashboard::ProfilesController do
  let(:user) { create(:user) }

  before do
    sign_in user
    allow(controller).to receive(:clear_session_user) ## Don't clear out the authenticated session
  end

  describe "#show" do
    it "show the user profile if user exists" do
      get :show, params: { id: user.user_key }
      expect(response).to be_successful
    end

    it "redirects to root if user does not exist" do
      expect do
        get :show, params: { id: 'johndoe666' }
      end.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe "#edit" do
    it "show edit form when user edits own profile" do
      get :edit, params: { id: user.user_key }
      expect(response).to be_successful
      expect(response).to render_template('hyrax/dashboard/profiles/edit')
      expect(flash[:alert]).to be_nil
    end

    context "when user attempts to edit another profile" do
      let(:another_user) { create(:user) }

      context 'with default abilities' do
        it "is unauthorized" do
          expect(controller.current_ability).to receive(:can?).with(:edit, another_user).and_return(false)
          get :edit, params: { id: another_user.to_param }
          expect(response).to render_template(:unauthorized)
        end
      end

      context 'with a custom ability' do
        before do
          allow(controller.current_ability).to receive(:can?).with(:edit, another_user).and_return(true)
        end

        it "allows user to edit another user's profile" do
          get :edit, params: { id: another_user.to_param }
          expect(response).to be_successful
          expect(response).not_to redirect_to(routes.url_helpers.dashboard_profile_path(another_user.to_param, locale: 'en'))
          expect(flash[:alert]).to be_nil
        end
      end
    end

    context "when the user has trophies" do
      let(:work1) { valkyrie_create(:hyrax_work, title: ["w1"]) }
      let(:work2) { valkyrie_create(:hyrax_work, title: ["w2"]) }
      let(:work3) { valkyrie_create(:hyrax_work, title: ["w3"]) }
      let!(:trophy1) { user.trophies.create!(work_id: work1.id) }
      let!(:trophy2) { user.trophies.create!(work_id: work2.id) }
      let!(:trophy3) { user.trophies.create!(work_id: work3.id) }

      it "show the user profile if user exists" do
        get :edit, params: { id: user.user_key }
        expect(response).to be_successful
        expect(assigns[:trophies]).to all(be_kind_of Hyrax::TrophyPresenter)
        expect(assigns[:trophies].map(&:id)).to match_array [work1.id, work2.id, work3.id]
      end
    end
  end

  describe "#update" do
    context "the profile of another user" do
      let(:another_user) { create(:user) }

      it "does not allow other users to update" do
        post :update, params: { id: another_user.user_key, user: { avatar: nil } }
        expect(response).to render_template(:unauthorized)
      end
    end

    it "sets an avatar and redirect to profile" do
      expect(user.avatar?).to be false
      expect(UserEditProfileEventJob).to receive(:perform_later).with(user)
      f = fixture_file_upload('/1.5mb-avatar.jpg', 'image/jpg')
      post :update, params: { id: user.user_key, user: { avatar: f } }
      expect(response).to redirect_to(routes.url_helpers.dashboard_profile_path(user.to_param, locale: 'en'))
      expect(flash[:notice]).to include("Your profile has been updated")
      expect(User.find_by_user_key(user.user_key).avatar?).to be true
    end
    it "validates the content type of an avatar" do
      expect(UserEditProfileEventJob).to receive(:perform_later).never
      f = fixture_file_upload('/image.jp2', 'image/jp2')
      post :update, params: { id: user.user_key, user: { avatar: f } }
      expect(response).to redirect_to(routes.url_helpers.edit_dashboard_profile_path(user.to_param, locale: 'en'))
      expect(flash[:alert]).to include("Avatar You are not allowed to upload \"jp2\" files, allowed types: jpg, jpeg, png, gif, bmp, tif, tiff")
    end
    it "validates the size of an avatar" do
      f = fixture_file_upload('/4-20.png', 'image/png')
      expect(UserEditProfileEventJob).to receive(:perform_later).never
      post :update, params: { id: user.user_key, user: { avatar: f } }
      expect(response).to redirect_to(routes.url_helpers.edit_dashboard_profile_path(user.to_param, locale: 'en'))
      expect(flash[:alert]).to include("Avatar file size must be less than 2MB")
    end

    context "user with existing avatar" do
      before do
        f = fixture_file_upload('/world.png', 'image/png')
        user.update(avatar: f)
      end

      it "deletes an avatar" do
        expect(UserEditProfileEventJob).to receive(:perform_later).with(user)
        post :update, params: { id: user.user_key, user: { remove_avatar: 'true' } }
        expect(response).to redirect_to(routes.url_helpers.dashboard_profile_path(user.to_param, locale: 'en'))
        expect(flash[:notice]).to include("Your profile has been updated")
        expect(User.find_by_user_key(user.user_key).avatar?).to be false
      end
    end

    it "sets an social handles" do
      post :update, params: { id: user.user_key, user: { twitter_handle: 'twit', facebook_handle: 'face', googleplus_handle: 'goo', linkedin_handle: "link", orcid: '0000-0000-1111-2222' } }
      expect(response).to redirect_to(routes.url_helpers.dashboard_profile_path(user.to_param, locale: 'en'))
      expect(flash[:notice]).to include("Your profile has been updated")
      u = User.find_by_user_key(user.user_key)
      expect(u.twitter_handle).to eq 'twit'
      expect(u.facebook_handle).to eq 'face'
      expect(u.googleplus_handle).to eq 'goo'
      expect(u.linkedin_handle).to eq 'link'
      expect(u.orcid).to eq 'https://orcid.org/0000-0000-1111-2222'
    end

    it 'displays a flash when invalid ORCID is entered' do
      expect(user.orcid).to be_blank
      post :update, params: { id: user.user_key, user: { orcid: 'foobar' } }
      expect(response).to redirect_to(routes.url_helpers.edit_dashboard_profile_path(user.to_param, locale: 'en'))
      expect(flash[:alert]).to include('Orcid must be a string of 19 characters, e.g., "0000-0000-0000-0000"')
    end

    context "when removing a trophy" do
      let(:work) { valkyrie_create(:hyrax_work, title: ["w1"]) }

      before do
        user.trophies.create!(work_id: work.id)
      end
      it "removes a trophy" do
        expect do
          post :update, params: { id: user.user_key, 'remove_trophy_' + work.id => 'yes' }
        end.to change { user.trophies.count }.by(-1)
        expect(response).to redirect_to(routes.url_helpers.dashboard_profile_path(user.to_param, locale: 'en'))
        expect(flash[:notice]).to include("Your profile has been updated")
      end
    end
  end
end
