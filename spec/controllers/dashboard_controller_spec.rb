require 'spec_helper'

describe DashboardController do

  describe "logged in user" do
    before do
      @user = FactoryGirl.find_or_create(:archivist)
      sign_in @user
      controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
    end
    describe "#index" do
      it "should return an array of documents" do
        xhr :get, :index
        response.should be_success
        response.should render_template('dashboard/index')        
      end
    end
  end
  describe "not logged in as a user" do
    describe "#index" do
      it "should return an error" do
        xhr :post, :index
        response.should_not be_success
      end
    end
  end
end
