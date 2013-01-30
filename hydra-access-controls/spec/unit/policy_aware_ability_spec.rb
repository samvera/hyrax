require 'spec_helper'

describe Hydra::PolicyAwareAbility do
  before do
    Hydra.stub(:config).and_return({
      :permissions=>{
        :discover => {:group =>"discover_access_group_tsim", :individual=>"discover_access_person_tsim"},
        :read => {:group =>"read_access_group_tsim", :individual=>"read_access_person_tsim"},
        :edit => {:group =>"edit_access_group_tsim", :individual=>"edit_access_person_tsim"},
        :owner => "depositor_tsim",
        :embargo_release_date => "embargo_release_date_dtsi",
      
        :inheritable => {
          :discover => {:group =>"inheritable_discover_access_group_tsim", :individual=>"inheritable_discover_access_person_tsim"},
          :read => {:group =>"inheritable_read_access_group_tsim", :individual=>"inheritable_read_access_person_tsim"},
          :edit => {:group =>"inheritable_edit_access_group_tsim", :individual=>"inheritable_edit_access_person_tsim"},
          :owner => "inheritable_depositor_tsim",
          :embargo_release_date => "inheritable_embargo_release_date_dtsi"
        }
    }})
  end
  before(:all) do
    class PolicyAwareClass
      include CanCan::Ability
      include Hydra::Ability
      include Hydra::PolicyAwareAbility
    end
    @policy = Hydra::AdminPolicy.new
    # Set the inheritable permissions
    @policy.default_permissions = [
        {:type=>"group", :access=>"read", :name=>"africana-faculty"},
        {:type=>"group", :access=>"edit", :name=>"cool_kids"},
        {:type=>"group", :access=>"edit", :name=>"in_crowd"},
        {:type=>"user", :access=>"read", :name=>"nero"},
        {:type=>"user", :access=>"edit", :name=>"julius_caesar"}
      ]
      
    @policy.save
    @asset = ModsAsset.new()
    @asset.admin_policy = @policy
    @asset.save
  end
  after(:all) { @policy.delete; @asset.delete }
  subject { PolicyAwareClass.new( User.new ) }
  
  describe "policy_pid_for" do
    it "should retrieve the pid doc for the current object's governing policy" do
      subject.policy_pid_for(@asset.pid).should == @policy.pid
    end
  end

  describe "policy_permissions_doc" do
    it "should retrieve the permissions doc for the current object's policy and store for re-use" do
      subject.should_receive(:get_permissions_solr_response_for_doc_id).with(@policy.pid).once.and_return("mock solr doc")
      subject.policy_permissions_doc(@policy.pid).should == "mock solr doc"
      subject.policy_permissions_doc(@policy.pid).should == "mock solr doc"
      subject.policy_permissions_doc(@policy.pid).should == "mock solr doc"
    end
  end
  describe "test_edit_from_policy" do
    it "should test_edit_from_policy"
  end
  describe "test_read_from_policy" do
    it "should test_read_from_policy"
  end
  describe "edit_groups_from_policy" do
    it "should retrieve the list of groups with edit access from the policy" do
      result = subject.edit_groups_from_policy(@policy.pid)
      result.length.should == 2
      result.should include("cool_kids","in_crowd")
    end
  end
  describe "edit_persons_from_policy" do
    it "should retrieve the list of individuals with edit access from the policy" do
      subject.edit_persons_from_policy(@policy.pid).should == ["julius_caesar"]
    end
  end
  describe "read_groups_from_policy" do
    it "should retrieve the list of groups with read access from the policy" do
      result = subject.read_groups_from_policy(@policy.pid)
      result.length.should == 3
      result.should include("cool_kids", "in_crowd", "africana-faculty")
    end
  end
  describe "read_persons_from_policy" do
    it "should retrieve the list of individuals with read access from the policy" do
      subject.read_persons_from_policy(@policy.pid).should == ["julius_caesar","nero"]
    end
  end
end
