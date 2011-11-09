# Need way to find way to stub current_user and RoleMapper in order to run these tests
require File.expand_path( File.join( File.dirname(__FILE__),'..','spec_helper') )

describe Hydra::AccessControlsEnforcement do

  describe "apply_gated_discovery" do
    before(:each) do
      @stub_user = User.new :email=>'archivist1@example.com'
      @stub_user.stubs(:is_being_superuser?).returns false
      @stub_user.stubs(:login).returns "fred"
      RoleMapper.stubs(:roles).with(@stub_user.login).returns(["archivist","researcher"])
      helper.stubs(:current_user).returns(@stub_user)
      @solr_parameters = {}
      @user_parameters = {}
    end
    it "should set query fields for the user id checking against the discover, access, read fields" do
      helper.send(:apply_gated_discovery, @solr_parameters, @user_parameters)
      ["discover","edit","read"].each do |type|
        @solr_parameters[:fq].first.should match(/#{type}_access_person_t\:#{@stub_user.login}/)      
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
      @solr_parameters[:fq].should include("(NOT embargo_release_date_dt:[NOW TO *]) OR depositor_t:#{@stub_user.login}")
      
      # @solr_parameters[:fq].should include("embargo_release_date_dt:[NOW TO *] AND  depositor_t:#{current_user.login}) AND NOT (NOT depositor_t:#{current_user.login} AND embargo_release_date_dt:[NOW TO *]")
    end
    
    describe "for superusers" do
      it "should return superuser access level" do
        stub_user = User.new
        stub_user.stubs(:login).returns "suzie"
        stub_user.stubs(:is_being_superuser?).returns true
        RoleMapper.stubs(:roles).with(stub_user.login).returns(["archivist","researcher"])
        helper.stubs(:current_user).returns(stub_user)
        helper.send(:apply_gated_discovery, @solr_parameters, @user_parameters)
        ["discover","edit","read"].each do |type|    
          @solr_parameters[:fq].first.should match(/#{type}_access_person_t\:\[\* TO \*\]/)          
        end
      end
      it "should not return superuser access to non-superusers" do
        stub_user = User.new
        stub_user.stubs(:login).returns "suzie"
        stub_user.stubs(:is_being_superuser?).returns false
        RoleMapper.stubs(:roles).with(stub_user.login).returns(["archivist","researcher"])
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
  
 describe "build_lucene_query" do

   it "should return fields for all roles the user is a member of checking against the discover, access, read fields" do
     stub_user = User.new :email=>'archivist1@example.com'
     stub_user.stubs(:is_being_superuser?).returns false
     helper.stubs(:current_user).returns(stub_user)
     # This example assumes that archivist1 is in the archivist and researcher groups.
     # Tried stubbing RoleMapper.roles instead, but that broke 26 other tests because mocha fails to release the expectation.
     # RoleMapper.stubs(:roles).with(stub_user.login).returns(["archivist", "researcher"])
     query = helper.send(:build_lucene_query, "query_string")
     # RoleMapper.stubs(:roles).with(stub_user.login).returns(["archivist", "researcher"])
     # query = helper.send(:build_lucene_query, "string")
     
     ["discover","edit","read"].each do |type|
       query.should match(/_query_\:\"#{type}_access_group_t\:archivist/) and
       query.should match(/_query_\:\"#{type}_access_group_t\:researcher/)
     end
     query.should match /^_query_:"\{!dismax qf=\$qf_dismax pf=\$pf_dismax\}query_string" AND NOT _query_:"info\\\\:fedora\/afmodel\\\\:FileAsset"/
   end
   it "should not have dismax clause if no user_query is suplied" do
     stub_user = User.new
     stub_user.stubs(:is_being_superuser?).returns false
     helper.stubs(:current_user).returns(stub_user)
     query = helper.send(:build_lucene_query, nil)
     query.should match /^NOT _query_:"info\\\\:fedora\/afmodel\\\\:FileAsset"/
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
end


