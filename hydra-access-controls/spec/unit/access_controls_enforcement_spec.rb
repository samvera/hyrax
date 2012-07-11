require 'spec_helper'
# Need way to find way to stub current_user and RoleMapper in order to run these tests

describe Hydra::AccessControlsEnforcement do
  before do
    class Rails; end
    Rails.stub(:root).and_return('spec/support')
    Rails.stub(:env).and_return('test')
  end
  before(:all) do
    class MockController
      include Hydra::AccessControlsEnforcement
      attr_accessor :params
      
      def user_key
        current_user.user_key
      end

      def session
      end
    end
  end
  subject { MockController.new }
  
  describe "When I am searching for content" do
    before do
      @solr_parameters = {}
      @user_parameters = {}
    end
    context "Given I am not logged in" do
      before do
        subject.stub(:current_user).and_return(User.new)
        subject.send(:apply_gated_discovery, @solr_parameters, @user_parameters)
      end
      it "Then I should be treated as a member of the 'public' group" do
        ["discover","edit","read"].each do |type|
          @solr_parameters[:fq].first.should match(/#{type}_access_group_t\:public/)      
        end
      end
      it "Then I should not be treated as a member of the 'registered' group" do
        @solr_parameters[:fq].first.should_not match(/registered/) 
      end
      it "Then I should not have individual or group permissions"
    end
    context "Given I am a registered user" do
      before do
        @user = FactoryGirl.build(:martia_morocco)
        @user.new_record = false
        User.stub(:find_by_user_key).and_return(@user)
        # This is a pretty fragile way to stub it...
        RoleMapper.stub(:byname).and_return(@user.user_key=>["faculty", "africana-faculty"])
        subject.stub(:current_user).and_return(@user)
        subject.send(:apply_gated_discovery, @solr_parameters, @user_parameters)
      end
      it "Then I should be treated as a member of the 'public' and 'registered' groups" do
        ["discover","edit","read"].each do |type|
          @solr_parameters[:fq].first.should match(/#{type}_access_group_t\:public/)  
          @solr_parameters[:fq].first.should match(/#{type}_access_group_t\:registered/)      
        end
      end
      it "Then I should see assets that I have discover, read, or edit access to" do
        ["discover","edit","read"].each do |type|
          @solr_parameters[:fq].first.should match(/#{type}_access_person_t\:#{@user.user_key}/)      
        end
      end
      it "Then I should see assets that my groups have discover, read, or edit access to" do
        ["faculty", "africana-faculty"].each do |group_id|
          ["discover","edit","read"].each do |type|
            @solr_parameters[:fq].first.should match(/#{type}_access_group_t\:#{group_id}/)      
          end
        end
      end
    end
  end
  
  describe "enforce_access_controls" do
    describe "when the method exists" do
      it "should call the method" do
        subject.params = {:action => :index}
        subject.enforce_access_controls.should be_true
      end
    end
    describe "when the method doesn't exist" do
      it "should not call the method, but should return true" do
        subject.params = {:action => :facet}
        subject.enforce_access_controls.should be_true
      end
    end
  end
  describe "enforce_show_permissions" do
    it "should allow a user w/ edit permissions to view an embargoed object" do
      user = User.new :uid=>'testuser@example.com'
      user.stub(:is_being_superuser?).and_return false
      RoleMapper.stub(:roles).with(user.user_key).and_return(["archivist"])
      subject.stub(:current_user).and_return(user)
      subject.should_receive(:can?).with(:edit, nil).and_return(true)
      subject.stub(:can?).with(:read, nil).and_return(true)
      subject.instance_variable_set :@permissions_solr_document, SolrDocument.new({"edit_access_person_t"=>["testuser@example.com"], "embargo_release_date_dt"=>(Date.parse(Time.now.to_s)+2).to_s})

      subject.params = {}
      subject.should_receive(:load_permissions_from_solr) #This is what normally sets @permissions_solr_document
      lambda {subject.send(:enforce_show_permissions, {}) }.should_not raise_error Hydra::AccessDenied
    end
    it "should prevent a user w/o edit permissions from viewing an embargoed object" do
      user = User.new :uid=>'testuser@example.com'
      user.stub(:is_being_superuser?).and_return false
      RoleMapper.stub(:roles).with(user.user_key).and_return([])
      subject.stub(:current_user).and_return(user)
      subject.should_receive(:can?).with(:edit, nil).and_return(false)
      subject.stub(:can?).with(:read, nil).and_return(true)
      subject.params = {}
      subject.instance_variable_set :@permissions_solr_document, SolrDocument.new({"edit_access_person_t"=>["testuser@example.com"], "embargo_release_date_dt"=>(Date.parse(Time.now.to_s)+2).to_s})
      subject.should_receive(:load_permissions_from_solr) #This is what normally sets @permissions_solr_document
      lambda {subject.send(:enforce_show_permissions, {})}.should raise_error Hydra::AccessDenied, "This item is under embargo.  You do not have sufficient access privileges to read this document."
    end
  end
  describe "apply_gated_discovery" do
    before(:each) do
      @stub_user = User.new :uid=>'archivist1@example.com'
      @stub_user.stub(:is_being_superuser?).and_return false
      RoleMapper.stub(:roles).with(@stub_user.user_key).and_return(["archivist","researcher"])
      subject.stub(:current_user).and_return(@stub_user)
      @solr_parameters = {}
      @user_parameters = {}
    end
    it "should set query fields for the user id checking against the discover, access, read fields" do
      subject.send(:apply_gated_discovery, @solr_parameters, @user_parameters)
      ["discover","edit","read"].each do |type|
        @solr_parameters[:fq].first.should match(/#{type}_access_person_t\:#{@stub_user.user_key}/)      
      end
    end
    it "should set query fields for all roles the user is a member of checking against the discover, access, read fields" do
      subject.send(:apply_gated_discovery, @solr_parameters, @user_parameters)
      ["discover","edit","read"].each do |type|
        @solr_parameters[:fq].first.should match(/#{type}_access_group_t\:archivist/)        
        @solr_parameters[:fq].first.should match(/#{type}_access_group_t\:researcher/)        
      end
    end
    
    describe "(DEPRECATED) for superusers" do
      it "should return superuser access level" do
        stub_user = User.new(:uid=>'suzie@example.com')
        stub_user.stub(:is_being_superuser?).and_return true
        RoleMapper.stub(:roles).with(stub_user.user_key).and_return(["archivist","researcher"])
        subject.stub(:current_user).and_return(stub_user)
        subject.send(:apply_gated_discovery, @solr_parameters, @user_parameters)
        ["discover","edit","read"].each do |type|    
          @solr_parameters[:fq].first.should match(/#{type}_access_person_t\:\[\* TO \*\]/)          
        end
      end
      it "should not return superuser access to non-superusers" do
        stub_user = User.new(:uid=>'suzie@example.com')
        stub_user.stub(:is_being_superuser?).and_return false
        RoleMapper.stub(:roles).with(stub_user.user_key).and_return(["archivist","researcher"])
        subject.stub(:current_user).and_return(stub_user)
        subject.send(:apply_gated_discovery, @solr_parameters, @user_parameters)
        ["discover","edit","read"].each do |type|
          @solr_parameters[:fq].should_not include("#{type}_access_person_t\:\[\* TO \*\]")              
        end
      end
    end

  end
  
  describe "exclude_unwanted_models" do
    before(:each) do
      stub_user = User.new :uid=>'archivist1@example.com'
      stub_user.stub(:is_being_superuser?).and_return false
      subject.stub(:current_user).and_return(stub_user)
      @solr_parameters = {}
      @user_parameters = {}
    end
    it "should set solr query parameters to filter out FileAssets" do
      subject.send(:exclude_unwanted_models, @solr_parameters, @user_parameters)
      @solr_parameters[:fq].should include("-has_model_s:\"info:fedora/afmodel:FileAsset\"")  
    end
  end
end


