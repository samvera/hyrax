require 'spec_helper'

describe Hydra::FileAssetsController do
  include Devise::TestHelpers
  before do
    session[:user]='bob'
  end

  it "should be restful" do
    { :get => "/hydra/file_assets" }.should route_to(:controller=>'hydra/file_assets', :action=>'index')
    { :get => "/hydra/file_assets/3" }.should route_to(:controller=>'hydra/file_assets', :action=>'show', :id=>"3")
    { :delete=> "/hydra/file_assets/3" }.should route_to(:controller=>'hydra/file_assets', :action=>'destroy', :id=>"3")
    { :put=>"/hydra/file_assets/3" }.should route_to(:controller=>'hydra/file_assets', :action=>'update', :id=>"3")
    { :get => "/hydra/file_assets/3/edit" }.should route_to(:controller=>'hydra/file_assets', :action=>'edit', :id=>"3")
    { :get =>"/hydra/file_assets/new" }.should route_to(:controller=>'hydra/file_assets', :action=>'new')
    { :post => "/hydra/file_assets" }.should route_to(:controller=>'hydra/file_assets', :action=>'create')
    
  end
  
  describe "index" do
    
    it "should find all file assets in the repo if no container_id is provided" do
      ActiveFedora::SolrService.should_receive(:query).with("has_model_s:info\\:fedora\\/afmodel\\:FileAsset", {:sort=>["system_create_dt asc"]}).and_return("solr result")
      controller.stub(:load_permissions_from_solr)
      ActiveFedora::Base.should_receive(:new).never
      xhr :get, :index
      assigns[:solr_result].should == "solr result"
    end
    it "should find all file assets belonging to a given container object if asset_id is provided" do
      pid = 'hydrangea:fixture_mods_article3'
      xhr :get, :index, :asset_id=>pid
      assigns[:response][:response][:docs].first["id"].should == "hydrangea:fixture_file_asset1"
      assigns[:document_list].first.id.should == "hydrangea:fixture_file_asset1"
      
      assigns[:container_response][:response][:docs].first["id"].should == "hydrangea:fixture_mods_article3"
      assigns[:document].id.should == "hydrangea:fixture_mods_article3"
      assigns[:solr_result].first["id"].should == "hydrangea:fixture_file_asset1"
      assigns[:container].should == ModsAsset.find('hydrangea:fixture_mods_article3')
    end
    
  end

  describe "new" do
    it "should set :container_id to value of :container_id if available" do
      xhr :get, :new, :asset_id=>"_PID_"
      @controller.params[:asset_id].should == "_PID_"
    end
  end

  describe "show" do
    it "should redirect back if current_user does not have read or edit permissions" do
      mock_user = double("User")
      mock_user.stub(:email).and_return("fake_user@example.com")
      mock_user.stub(:persisted?).and_return(true)
      mock_user.stub(:new_record?).and_return(false)
      controller.stub(:current_user).and_return(mock_user)
      request.env["HTTP_REFERER"] = "http://example.com/?q=search"
      get(:show, :id=>"hydrangea:fixture_file_asset1")
      response.should redirect_to(root_url)
    end
     it "should redirect to the login page if the user is not logged in" do
      mock_user = double("User")
      mock_user.stub(:email).and_return("fake_user@example.com")
      mock_user.stub(:persisted?).and_return(false)
      mock_user.stub(:new_record?).and_return(true)
      controller.stub(:current_user).and_return(mock_user)
      request.env["HTTP_REFERER"] = "http://example.com/?q=search"
      get(:show, :id=>"hydrangea:fixture_file_asset1")
      response.should redirect_to("http://test.host/users/sign_in")
      session['user_return_to'].should =~ /fixture_file_asset1/
    end
    it "should redirect to index view if the file does not exist" do
      get(:show, :id=>"example:invalid_object")
      response.should redirect_to(:action => 'index')
    end
  end
  
  describe "create" do
    it "should create and save a file asset from the given params" do
      mock_fa = double("FileAsset")
      mock_file = double("File")
      mock_fa.stub(:pid).and_return("foo:pid")
      controller.should_receive(:create_and_save_file_assets_from_params).and_return([mock_fa])
      xhr :post, :create, :Filedata=>[mock_file], :Filename=>"Foo File"
    end
    it "if container_id is provided, should associate the created file asset wtih the container" do
      stub_fa = double("FileAsset")
      stub_fa.stub(:pid).and_return("foo:pid")
      stub_fa.stub(:label).and_return("Foo File")
      mock_file = double("File")
      controller.should_receive(:create_and_save_file_assets_from_params).and_return([stub_fa])
      controller.should_receive(:associate_file_asset_with_container)      
      xhr :post, :create, :Filedata=>[mock_file], :Filename=>"Foo File", :container_id=>"_PID_"
    end
    it "should redirect back to edit view if no Filedata is provided but container_id is provided" do
      controller.should_receive(:model_config).at_least(:once).and_return(controller.workflow_config[:mods_assets])
      xhr :post, :create, :container_id=>"_PID_", :wf_step=>"files"
      response.should redirect_to catalog_path("_PID_", :wf_step=>"permissions")
      request.flash[:notice].should == "You must specify a file to upload."
    end
    it "should display a message that you need to select a file to upload if no Filedata is provided" do
      xhr :post, :create
      request.flash[:notice].include?("You must specify a file to upload.").should be_true
    end
    
  end

  describe "destroy" do
    it "should delete the asset identified by pid" do
      mock_obj = double("asset")
      mock_obj.should_receive(:delete)
      ActiveFedora::Base.should_receive(:find).with("__PID__", :cast=>true).and_return(mock_obj)
      delete(:destroy, :id => "__PID__")
    end
    it "should remove container relationship and perform proper garbage collection" do
      pending "relies on ActiveFedora implementing Base.file_objects_remove"
      mock_container = mock("asset")
      mock_container.should_receive(:file_objects_remove).with("_file_asset_pid_")
      FileAsset.should_receive(:garbage_collect).with("_file_asset_pid_")
      ActiveFedora::Base.should_receive(:find).with("_container_pid_", :cast=>true).and_return(mock_container)
      delete(:destroy, :id => "_file_asset_pid_", :asset_id=>"_container_pid_")
    end
  end
  
  describe "integration tests - " do
    before(:all) do
      class TestObj < ActiveFedora::Base
        include ActiveFedora::FileManagement
      end

      ActiveFedora::SolrService.register(ActiveFedora.solr_config[:url])
      @test_container = TestObj.new
      @test_container.add_relationship(:is_member_of, "info:fedora/foo:1")
      @test_container.add_relationship(:has_collection_member, "info:fedora/foo:2")
      @test_container.save
      
      @test_fa = FileAsset.new
      @test_fa.add_relationship(:is_part_of, @test_container)
      @test_fa.save
    end

    after(:all) do
     @test_container.delete
     @test_fa.delete
     Object.send(:remove_const, :TestObj)
    end

    describe "index" do
      it "should retrieve the container object and its file assets" do
        #xhr :get, :index, :container_id=>@test_container.pid
        get :index, {:asset_id=>@test_container.pid}
        @controller.params[:asset_id].should_not be_nil
        assigns(:solr_result).should_not be_nil
        #puts assigns(:solr_result).inspect
        assigns(:container).file_objects(:response_format=>:id_array).should include(@test_fa.pid)
        assigns(:container).file_objects(:response_format=>:id_array).should include("foo:2")
      end
    end
    
    describe "create" do
      before :each do
        mock_user = double("User")
        mock_user.stub(:user_key).and_return('user@example.com')
        mock_warden = double("Warden")
        mock_warden.stub(:authenticate).and_return(mock_user)
        request.env['warden'] = mock_warden
      end

      it "should set is_part_of relationship on the new File Asset pointing back at the container" do
        test_file = fixture_file_upload('spec/fixtures/small_file.txt', 'text/plain')
        filename = "My File Name"
        post :create, {:Filedata=>[test_file], :Filename=>filename, :container_id=>@test_container.pid}
        assigns(:file_asset).ids_for_outbound(:is_part_of).should == [@test_container.pid] 
        retrieved_fa = FileAsset.find(@test_fa.pid).ids_for_outbound(:is_part_of).should == [@test_container.pid]
      end
    end
  end
end
