require 'spec_helper'

describe DashboardController do

  describe "logged in user" do
    before (:each) do
      @user = FactoryGirl.find_or_create(:archivist)
      sign_in @user
      controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
    end
    describe "#index" do
      before (:each) do
        xhr :get, :index
      end
      it "should be a success" do
        response.should be_success
        response.should render_template('dashboard/index')        
      end
      it "should return an array of documents I can edit" do
        @user_results = Blacklight.solr.find Hash[:fq=>["edit_access_group_t:public OR edit_access_person_t:#{@user.login}"]]
        assigns(:document_list).count.should eql(@user_results.docs.count)
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
