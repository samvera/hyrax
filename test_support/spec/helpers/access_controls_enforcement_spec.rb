# Need way to find way to stub current_user and RoleMapper in order to run these tests
require File.expand_path( File.join( File.dirname(__FILE__),'..','spec_helper') )

describe Hydra::AccessControlsEnforcement do
  describe "enforce_access_controls" do
    describe "when the method exists" do
      it "should call the method" do
        params[:action] = :index
        helper.enforce_access_controls.should be_true
      end
    end
    describe "when the method doesn't exist" do
      it "should not call the method, but should return true" do
        params[:action] = :facet
        helper.enforce_access_controls.should be_true
      end
    end
  end
  describe "enforce_show_permissions" do
    it "should allow a user w/ edit permissions to view an embargoed object" do
      user = User.new :email=>'testuser@example.com'
      user.stubs(:is_being_superuser?).returns false
      RoleMapper.stubs(:roles).with(user.email).returns(["archivist"])
      helper.stubs(:current_user).returns(user)
      helper.stubs(:load_permissions_from_solr).returns("")
      helper.stubs(:can?).with(:edit, nil).returns(true)
      helper.stubs(:can?).with(:read, nil).returns(true)
      @permissions_solr_document = SolrDocument.new({"edit_access_person_t"=>["testuser@example.com"], "embargo_release_date_dt"=>(Date.parse(Time.now.to_s)+2).to_s})
      helper.send(:enforce_show_permissions, {})
      flash[:alert].should be_nil
    end
    it "should prevent a user w/o edit permissions from viewing an embargoed object" do
      user = User.new :email=>'testuser@example.com'
      user.stubs(:is_being_superuser?).returns false
      RoleMapper.stubs(:roles).with(user.email).returns([])
      helper.stubs(:current_user).returns(user)
      helper.stubs(:load_permissions_from_solr).returns("")
      helper.stubs(:can?).with(:edit, nil).returns(false)
      helper.stubs(:can?).with(:read, nil).returns(true)
      helper.stubs(:redirect_to)
      @permissions_solr_document = SolrDocument.new({"edit_access_person_t"=>["testuser@example.com"], "embargo_release_date_dt"=>(Date.parse(Time.now.to_s)+2).to_s})
      lambda {helper.send(:enforce_show_permissions, {})}.should raise_error Hydra::AccessDenied, "This item is under embargo.  You do not have sufficient access privileges to read this document."
    end
  end
  describe "apply_gated_discovery" do
    before(:each) do
      @stub_user = User.new :email=>'archivist1@example.com'
      @stub_user.stubs(:is_being_superuser?).returns false
      RoleMapper.stubs(:roles).with(@stub_user.email).returns(["archivist","researcher"])
      helper.stubs(:current_user).returns(@stub_user)
      @solr_parameters = {}
      @user_parameters = {}
    end
    it "should set query fields for the user id checking against the discover, access, read fields" do
      helper.send(:apply_gated_discovery, @solr_parameters, @user_parameters)
      ["discover","edit","read"].each do |type|
        @solr_parameters[:fq].first.should match(/#{type}_access_person_t\:#{@stub_user.email}/)      
      end
    end
    it "should set query fields for all roles the user is a member of checking against the discover, access, read fields" do
      helper.send(:apply_gated_discovery, @solr_parameters, @user_parameters)
      ["discover","edit","read"].each do |type|
        @solr_parameters[:fq].first.should match(/#{type}_access_group_t\:archivist/)        
        @solr_parameters[:fq].first.should match(/#{type}_access_group_t\:researcher/)        
      end
    end
    # it "should filter out any content whose embargo date is in the future" do
    #   helper.send(:apply_gated_discovery, @solr_parameters, @user_parameters)
    #   @solr_parameters[:fq].should include("-embargo_release_date_dt:[NOW TO *]")
    # end
    it "should allow content owners access to their embargoed content" do
      pending
      helper.send(:apply_gated_discovery, @solr_parameters, @user_parameters)
      @solr_parameters[:fq].should include("(NOT embargo_release_date_dt:[NOW TO *]) OR depositor_t:#{@stub_user.email}")
      
      # @solr_parameters[:fq].should include("embargo_release_date_dt:[NOW TO *] AND  depositor_t:#{current_user.email}) AND NOT (NOT depositor_t:#{current_user.email} AND embargo_release_date_dt:[NOW TO *]")
    end
    
    describe "for superusers" do
      it "should return superuser access level" do
        stub_user = User.new(:email=>'suzie@example.com')
        stub_user.stubs(:is_being_superuser?).returns true
        RoleMapper.stubs(:roles).with(stub_user.email).returns(["archivist","researcher"])
        helper.stubs(:current_user).returns(stub_user)
        helper.send(:apply_gated_discovery, @solr_parameters, @user_parameters)
        ["discover","edit","read"].each do |type|    
          @solr_parameters[:fq].first.should match(/#{type}_access_person_t\:\[\* TO \*\]/)          
        end
      end
      it "should not return superuser access to non-superusers" do
        stub_user = User.new(:email=>'suzie@example.com')
        stub_user.stubs(:is_being_superuser?).returns false
        RoleMapper.stubs(:roles).with(stub_user.email).returns(["archivist","researcher"])
        helper.stubs(:current_user).returns(stub_user)
        helper.send(:apply_gated_discovery, @solr_parameters, @user_parameters)
        ["discover","edit","read"].each do |type|
          @solr_parameters[:fq].should_not include("#{type}_access_person_t\:\[\* TO \*\]")              
        end
      end
    end

  end
  
  describe "exclude_unwanted_models" do
    before(:each) do
      stub_user = User.new :email=>'archivist1@example.com'
      stub_user.stubs(:is_being_superuser?).returns false
      helper.stubs(:current_user).returns(stub_user)
      @solr_parameters = {}
      @user_parameters = {}
    end
    it "should set solr query parameters to filter out FileAssets" do
      helper.send(:exclude_unwanted_models, @solr_parameters, @user_parameters)
      @solr_parameters[:fq].should include("-has_model_s:\"info:fedora/afmodel:FileAsset\"")  
    end
  end
end


