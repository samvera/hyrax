require 'spec_helper'

describe DashboardController do
  
  context "with an unauthenticated user" do

    it "redirects to sign-in page" do
      get :index
      expect(response).to be_redirect
      expect(flash[:alert]).to eq("You need to sign in or sign up before continuing.")
    end

  end

  context "with an authenticated user" do

    before do
      @user = FactoryGirl.find_or_create(:user_with_mail)
      sign_in @user
    end

    it "renders the dashboard with the user's info" do
      get :index
      expect(response).to be_successful
      expect(assigns(:user)).to eq(@user)
    end

    it "gathers the user's recent activity" do
      get :index
      expect(assigns(:activity)).to be_empty
    end

    it "gathers the user's notifications" do
      get :index
      expect(assigns(:notifications)).to be_truthy
    end

    context "with activities" do

      let(:activity) { double }
      before do
        allow(activity).to receive(:map).and_return(activity)
        expect_any_instance_of(User).to receive(:get_all_user_activity).and_return(activity)
      end

      it "gathers the user's recent activity within the default amount of time" do
        get :index
        expect(assigns(:activity)).to eq activity
      end

      it "returns results in JSON" do
        get :activity
        expect(response).to be_successful
      end 

    end

  end

end
