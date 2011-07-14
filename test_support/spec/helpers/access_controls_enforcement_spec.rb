# Need way to find way to stub current_user and RoleMapper in order to run these tests
require File.expand_path( File.join( File.dirname(__FILE__),'..','spec_helper') )

describe Hydra::AccessControlsEnforcement do
  before(:each) do
    @extra_controller_params = {}
  end
  
  describe "enforce_access_controls" do
    describe "[index]" do
      it "should trigger enforce_index_permissions" do
        helper.params[:action] = "index"
        helper.expects(:enforce_index_permissions)
        helper.enforce_access_controls
      end
    end
    describe "[show]" do
      it "should trigger enforce_show_permissions" do
        helper.params[:action] = "show"
        helper.expects(:enforce_show_permissions)
        helper.enforce_access_controls
      end
    end
    
    describe "[edit]" do
      it "should trigger enforce_edit_permissions" do
        helper.params[:action] = "edit"
        helper.expects(:enforce_edit_permissions)
        helper.enforce_access_controls
      end
    end
    
  end
  
  describe "add_access_controls_to_solr_params" do
    it "should set up gated discovery" do
      stub_solr_params = {}
      helper.stubs(:reader?).returns(false)
      helper.stubs(:params).returns({:action=>:index})
      helper.expects(:apply_gated_discovery).with(stub_solr_params, {})
      helper.send(:add_access_controls_to_solr_params, stub_solr_params, {})
    end
    it "should make blacklight use the :public_qt response handler if user does not have read permissions" do
      stub_solr_params = {}
      helper.stubs(:solr_parameters).returns(stub_solr_params)
      helper.stubs(:reader?).returns(false)
      helper.stubs(:params).returns({:action=>:index})
      helper.stubs(:apply_gated_discovery)
      helper.send(:add_access_controls_to_solr_params, stub_solr_params, {})
      stub_solr_params[:qt].should == Blacklight.config[:public_qt]
    end
  end
  
  describe "enforce_index_permissions" do
    it "should be defined but do nothing (currently enforce_index_permissions doesn't do anything but it's there if you want to override)" do
      # just ensure that calling the method does not raise an error
      helper.send(:enforce_index_permissions)
    end
  end
  
  describe "enforce_show_permissions" do
    it "should deny access to documents if role does not have read permissions" do
      helper.stubs(:reader?).returns(false)
      helper.stubs(:params).returns({:action=>:show,:id=>"hydrangea:fixture_mods_article1"}) # the permissions from this are not actually used because we stub the :reader? method
      helper.expects(:redirect_to).with(:f => nil, :q => nil, :action => 'index')
      helper.send(:enforce_show_permissions)
      flash[:notice].should ==  "You do not have sufficient access privileges to read this document, which has been marked private."
    end
  end
  describe "enforce_edit_permissions" do
    it "should deny access to documents if role does not have edit permissions" do
      helper.stubs(:editor?).returns(false)
      helper.stubs(:params).returns({:action=>:edit,:id=>"hydrangea:fixture_mods_article1"} ) # the permissions from this are not actually used because we stub the :editor? method
      helper.expects(:redirect_to).with(:action => :show)
      helper.send(:enforce_edit_permissions)
      flash[:notice].should == "You do not have sufficient privileges to edit this document. You have been redirected to the read-only view."
    end  
  end
  describe "apply_gated_discovery" do
    it "should set the query using build_lucene_query" do
      stub_solr_params = {}
      helper.stubs(:solr_parameters).returns(stub_solr_params)
      user_query = "my important query"
      helper.stubs(:params).returns({:q=>user_query} )
      helper.expects(:build_lucene_query).with(user_query).returns("stub lucene query")
      helper.send(:apply_gated_discovery, stub_solr_params, {})
      stub_solr_params[:q].should == "stub lucene query"
    end
  end
  
  describe "build_lucene_query" do

    it "should return fields for all roles the user is a member of checking against the discover, access, read fields" do
     stub_user = User.new
     stub_user.stubs(:is_being_superuser?).returns false
     stub_user.stubs(:login).returns "archivist1"
     helper.stubs(:current_user).returns(stub_user)
     # This example assumes that archivist1 is in the archivist and researcher groups.
     # Tried stubbing RoleMapper.roles instead, but that broke 26 other tests because mocha fails to release the expectation.
     # RoleMapper.stubs(:roles).with(stub_user.login).returns(["archivist", "researcher"])
     query = helper.send(:build_lucene_query, "string")
     
     ["discover","edit","read"].each do |type|
       query.should match(/_query_\:\"#{type}_access_group_t\:archivist/) and
       query.should match(/_query_\:\"#{type}_access_group_t\:researcher/)
     end
    end
    it "should return fields for all the person specific discover, access, read fields" do
     stub_user = User.new
     stub_user.stubs(:is_being_superuser?).returns false
     helper.stubs(:current_user).returns(stub_user)
     query = helper.send(:build_lucene_query, "string")
     ["discover","edit","read"].each do |type|
       query.should match(/_query_\:\"#{type}_access_person_t\:#{stub_user.login}/)
     end
    end
    describe "for superusers" do
     it "should return superuser access level" do
       stub_user = User.new
       stub_user.stubs(:is_being_superuser?).returns true
       helper.stubs(:current_user).returns(stub_user)
       query = helper.send(:build_lucene_query, "string")
       ["discover","edit","read"].each do |type|         
         query.should match(/_query_\:\"#{type}_access_person_t\:\[\* TO \*\]/)
       end
     end
     it "should not return superuser access to non-superusers" do
       stub_user = User.new
       stub_user.stubs(:is_being_superuser?).returns false
       helper.stubs(:current_user).returns(stub_user)
       query = helper.send(:build_lucene_query, "string")
       ["discover","edit","read"].each do |type|
         query.should_not match(/_query_\:\"#{type}_access_person_t\:\[\* TO \*\]/)
       end
     end
    end
  end

  it "should have necessary fieldnames from initializer" do
   Hydra.config[:permissions][:catchall].should_not be_nil
   Hydra.config[:permissions][:discover][:group].should_not be_nil
   Hydra.config[:permissions][:discover][:individual].should_not be_nil
   Hydra.config[:permissions][:read][:group].should_not be_nil
   Hydra.config[:permissions][:read][:individual].should_not be_nil
   Hydra.config[:permissions][:edit][:group].should_not be_nil
   Hydra.config[:permissions][:edit][:individual].should_not be_nil
   Hydra.config[:permissions][:owner].should_not be_nil
   Hydra.config[:permissions][:embargo_release_date].should_not be_nil
  end

  # SPECS FOR SINGLE DOCUMENT REQUESTS
  describe 'Get Document Permissions By Id' do
   before(:each) do
     @doc_id = 'hydrangea:fixture_mods_article1'
     @bad_id = "redrum"
     @response2, @document = helper.get_permissions_solr_response_for_doc_id(@doc_id)
   end

   it "should raise Blacklight::InvalidSolrID for an unknown id" do
     lambda {
       helper.get_permissions_solr_response_for_doc_id(@bad_id)
     }.should raise_error(Blacklight::Exceptions::InvalidSolrID)
   end
   
   it "should raise Blacklight::InvalidSolrID for nil id" do
     lambda {
       helper.get_permissions_solr_response_for_doc_id(nil)
     }.should raise_error(Blacklight::Exceptions::InvalidSolrID)
   end

   it "should have a non-nil result for a known id" do
     @document.should_not == nil
   end
   it "should have a single document in the response for a known id" do
     @response2.docs.size.should == 1
   end
   it 'should have the expected value in the id field' do
     @document.id.should == @doc_id
   end
   it 'should have non-nil values for permissions fields that are set on the object' do
     @document.get(Hydra.config[:permissions][:catchall]).should_not be_nil
     @document.get(Hydra.config[:permissions][:discover][:group]).should_not be_nil
     @document.get(Hydra.config[:permissions][:edit][:group]).should_not be_nil
     @document.get(Hydra.config[:permissions][:edit][:individual]).should_not be_nil
     @document.get(Hydra.config[:permissions][:read][:group]).should_not be_nil
 
     # @document.get(Hydra.config[:permissions][:discover][:individual]).should_not be_nil
     # @document.get(Hydra.config[:permissions][:read][:individual]).should_not be_nil
     # @document.get(Hydra.config[:permissions][:owner]).should_not be_nil
     # @document.get(Hydra.config[:permissions][:embargo_release_date]).should_not be_nil
   end
  end
   
end


