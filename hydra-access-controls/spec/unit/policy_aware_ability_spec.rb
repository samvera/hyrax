require 'spec_helper'

describe Hydra::PolicyAwareAbility do
  before do
    Hydra.stub(:config).and_return({
      :permissions=>{
        :discover => {:group =>"discover_access_group_ssim", :individual=>"discover_access_person_ssim"},
        :read => {:group =>"read_access_group_ssim", :individual=>"read_access_person_ssim"},
        :edit => {:group =>"edit_access_group_ssim", :individual=>"edit_access_person_ssim"},
        :owner => "depositor_ssim",
        :embargo_release_date => "embargo_release_date_dtsi",
      
        :inheritable => {
          :discover => {:group =>"inheritable_discover_access_group_ssim", :individual=>"inheritable_discover_access_person_ssim"},
          :read => {:group =>"inheritable_read_access_group_ssim", :individual=>"inheritable_read_access_person_ssim"},
          :edit => {:group =>"inheritable_edit_access_group_ssim", :individual=>"inheritable_edit_access_person_ssim"},
          :owner => "inheritable_depositor_ssim",
          :embargo_release_date => "inheritable_embargo_release_date_dtsi"
        }
    }})
  end
  before(:all) do
    class PolicyAwareClass
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
    @asset = ModsAsset.new
    @asset.admin_policy = @policy
    @asset.save
  end
  after(:all) do
    @policy.delete
    @asset.delete 
    Object.send(:remove_const, :PolicyAwareClass)
  end 
  subject { PolicyAwareClass.new( User.new ) }
  
  describe "policy_pid_for" do
    before do
      @policy2 = Hydra::AdminPolicy.new
      @policy2.default_permissions = 
        [
         {:type=>"group", :access=>"read", :name=>"untenured-faculty"},
         {:type=>"group", :access=>"edit", :name=>"awesome_kids"},
         {:type=>"group", :access=>"edit", :name=>"bad_crowd"},
         {:type=>"user", :access=>"read", :name=>"constantine"},
         {:type=>"user", :access=>"edit", :name=>"brutus"}
        ]
      @policy2.save
      @asset2 = ModsAsset.new
      @asset2.admin_policy = @policy2
      @asset2.save
      @asset3 = ModsAsset.create
    end
    after do
      @policy2.delete
      @asset2.delete
      @asset3.delete
    end
    it "should retrieve the pid doc for the current object's governing policy" do
      subject.policy_pid_for(@asset.pid).should == @policy.pid
      subject.policy_pid_for(@asset2.pid).should == @policy2.pid
      subject.policy_pid_for(@asset3.pid).should be_nil
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
    context "public user" do
      it "should return false" do
        subject.stub(:user_groups).and_return(["public"])
        subject.test_edit_from_policy(@asset.pid).should be false
      end
    end
    context "registered user" do
      it "should return false" do
        subject.user_groups.should include("registered")
        subject.test_edit_from_policy(@asset.pid).should be false
      end
    end
    context "user with policy read access only" do
      it "should return false" do
        subject.current_user.stub(:user_key).and_return("nero")
        subject.test_edit_from_policy(@asset.pid).should be false
      end
    end
    context "user with policy edit access" do
      it "should return true" do
        subject.current_user.stub(:user_key).and_return("julius_caesar")
        subject.test_edit_from_policy(@asset.pid).should be true
      end
    end
    context "user in group with policy read access" do
      it "should return false" do
        subject.stub(:user_groups).and_return(["africana-faculty"])
        subject.test_edit_from_policy(@asset.pid).should be false
      end
    end
    context "user in group with policy edit access" do
      it "should return true" do
        subject.stub(:user_groups).and_return(["cool_kids"])
        subject.test_edit_from_policy(@asset.pid).should be true
      end
    end
  end
  describe "test_read_from_policy" do
    context "public user" do
      it "should return false" do
        subject.stub(:user_groups).and_return(["public"])
        subject.test_read_from_policy(@asset.pid).should be false
      end
    end
    context "registered user" do
      it "should return false" do
        subject.user_groups.should include("registered")
        subject.test_read_from_policy(@asset.pid).should be false
      end
    end
    context "user with policy read access only" do
      it "should return false" do
        subject.current_user.stub(:user_key).and_return("nero")
        subject.test_read_from_policy(@asset.pid).should be true
      end
    end
    context "user with policy edit access" do
      it "should return true" do
        subject.current_user.stub(:user_key).and_return("julius_caesar")
        subject.test_read_from_policy(@asset.pid).should be true
      end
    end
    context "user in group with policy read access" do
      it "should return false" do
        subject.stub(:user_groups).and_return(["africana-faculty"])
        subject.test_read_from_policy(@asset.pid).should be true
      end
    end
    context "user in group with policy edit access" do
      it "should return true" do
        subject.stub(:user_groups).and_return(["cool_kids"])
        subject.test_read_from_policy(@asset.pid).should be true
      end
    end
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
      expect(subject.edit_users_from_policy(@policy.pid)).to eq ["julius_caesar"]
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
      expect(subject.read_users_from_policy(@policy.pid)).to eq ["julius_caesar","nero"]
    end
  end
end
