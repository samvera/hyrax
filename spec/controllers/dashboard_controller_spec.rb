require 'spec_helper'

describe DashboardController do
  before do
    GenericFile.any_instance.stubs(:terms_of_service).returns('1')
    User.any_instance.stubs(:groups).returns([])
    controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
  end
  # This doesn't really belong here, but it works for now
  describe "authenticate!" do
    before(:each) do
      @user = FactoryGirl.find_or_create(:archivist)
      request.stubs(:headers).returns('REMOTE_USER' => @user.login).at_least_once
      @strategy = Devise::Strategies::HttpHeaderAuthenticatable.new(nil)
      @strategy.expects(:request).returns(request).at_least_once
    end
    it "should populate LDAP attrs if user is new" do
      User.stubs(:find_by_login).with(@user.login).returns(nil)
      User.expects(:create).with(login: @user.login).returns(@user).once
      User.any_instance.expects(:populate_attributes).once
      @strategy.should be_valid
      @strategy.authenticate!.should == :success
      sign_in @user
      get :index
    end
    it "should not populate LDAP attrs if user is not new" do
      User.stubs(:find_by_login).with(@user.login).returns(@user)
      User.expects(:create).with(login: @user.login).never
      User.any_instance.expects(:populate_attributes).never
      @strategy.should be_valid
      @strategy.authenticate!.should == :success
      sign_in @user
      get :index
    end
  end
  describe "logged in user" do
    before (:each) do
      @user = FactoryGirl.find_or_create(:archivist)
      sign_in @user
      controller.stubs(:clear_session_user) ## Don't clear out the authenticated session
      User.any_instance.stubs(:groups).returns([])
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
