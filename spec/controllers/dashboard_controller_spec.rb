require 'spec_helper'

describe DashboardController do
  before do
    GenericFile.any_instance.stub(:terms_of_service).and_return('1')
    User.any_instance.stub(:groups).and_return([])
    controller.stub(:clear_session_user) ## Don't clear out the authenticated session
  end
  # This doesn't really belong here, but it works for now
  describe "authenticate!" do
    # move to scholarsphere
    # before(:each) do
    #   @user = FactoryGirl.find_or_create(:archivist)
    #   request.stub(:headers).and_return('REMOTE_USER' => @user.login).at_least(:once)
    #   @strategy = Devise::Strategies::HttpHeaderAuthenticatable.new(nil)
    #   @strategy.should_receive(:request).and_return(request).at_least(:once)
    # end
    # after(:each) do
    #   @user.delete
    # end
    it "should populate LDAP attrs if user is new" do
      pending "This should only be in scholarsphere"
      User.stub(:find_by_login).with(@user.login).and_return(nil)
      User.should_receive(:create).with(login: @user.login).and_return(@user).once
      User.any_instance.should_receive(:populate_attributes).once
      @strategy.should be_valid
      @strategy.authenticate!.should == :success
      sign_in @user
      get :index
    end
    it "should not populate LDAP attrs if user is not new" do
      pending "This should only be in scholarsphere"
      User.stub(:find_by_login).with(@user.login).and_return(@user)
      User.should_receive(:create).with(login: @user.login).never
      User.any_instance.should_receive(:populate_attributes).never
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
      controller.stub(:clear_session_user) ## Don't clear out the authenticated session
      User.any_instance.stub(:groups).and_return([])
    end
    describe "#index" do
      before (:each) do
        xhr :get, :index
        # Make sure there are at least 3 files owned by @user. Otherwise, the tests aren't meaningful.
        if assigns(:document_list).count < 3
          files_count = assigns(:document_list).count
          until files_count == 3
            gf = GenericFile.new()
            gf.apply_depositor_metadata(@user)
            gf.save
            files_count += 1
          end
          xhr :get, :index
        end
      end
      it "should be a success" do
        response.should be_success
        response.should render_template('dashboard/index')
      end
      it "should return an array of documents I can edit" do
        editable_docs_response = Blacklight.solr.get "select", :params=>{:fq=>["edit_access_group_ssim:public OR edit_access_person_ssim:#{@user.user_key}"]}
        assigns(:result_set_size).should eql(editable_docs_response["response"]["numFound"])
        assigns(:document_list).each {|doc| doc.should be_kind_of SolrDocument}
      end
      context "with render views" do
        render_views
        it "should paginate" do          
          xhr :get, :index, per_page: 2
          response.should be_success
          response.should render_template('dashboard/index')
        end
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
