require 'spec_helper'

describe Hydra::PolicyAwareAbility do
  before do
    allow(Hydra.config.permissions).to receive(:inheritable).and_return({
        :discover => {:group =>"inheritable_discover_access_group_ssim", :individual=>"inheritable_discover_access_person_ssim"},
        :read => {:group =>"inheritable_read_access_group_ssim", :individual=>"inheritable_read_access_person_ssim"},
        :edit => {:group =>"inheritable_edit_access_group_ssim", :individual=>"inheritable_edit_access_person_ssim"},
        :owner => "inheritable_depositor_ssim",
        :embargo_release_date => "inheritable_embargo_release_date_dtsi"
    })
  end
  before do
    class PolicyAwareClass
      include Hydra::PolicyAwareAbility
    end
    @policy = Hydra::AdminPolicy.create
    # Set the inheritable permissions
    @policy.default_permissions.create [
        {:type=>"group", :access=>"read", :name=>"africana-faculty"},
        {:type=>"group", :access=>"edit", :name=>"cool_kids"},
        {:type=>"group", :access=>"edit", :name=>"in_crowd"},
        {:type=>"person", :access=>"read", :name=>"nero"},
        {:type=>"person", :access=>"edit", :name=>"julius_caesar"}
      ]

    @policy.save!
    @asset = ModsAsset.new
    @asset.admin_policy = @policy
    @asset.save!
  end
  after do
    # @policy.delete
    # @asset.delete
    Object.send(:remove_const, :PolicyAwareClass)
  end
  subject { PolicyAwareClass.new( User.new ) }

  describe "policy_pid_for" do
    before do
      @policy2 = Hydra::AdminPolicy.create
      @policy2.default_permissions.create [
         {:type=>"group", :access=>"read", :name=>"untenured-faculty"},
         {:type=>"group", :access=>"edit", :name=>"awesome_kids"},
         {:type=>"group", :access=>"edit", :name=>"bad_crowd"},
         {:type=>"person", :access=>"read", :name=>"constantine"},
         {:type=>"person", :access=>"edit", :name=>"brutus"}
        ]
      @policy2.save
      @asset2 = ModsAsset.new
      @asset2.admin_policy = @policy2
      @asset2.save
      @asset3 = ModsAsset.create
    end
    after do
      # @policy2.delete
      # @asset2.delete
      # @asset3.delete
    end
    it "should retrieve the pid doc for the current object's governing policy" do
      expect(subject.policy_pid_for(@asset.pid)).to eq @policy.pid
      expect(subject.policy_pid_for(@asset2.pid)).to eq @policy2.pid
      expect(subject.policy_pid_for(@asset3.pid)).to be_nil
    end
  end

  describe "policy_permissions_doc" do
    it "should retrieve the permissions doc for the current object's policy and store for re-use" do
      expect(subject).to receive(:get_permissions_solr_response_for_doc_id).with(@policy.pid).once.and_return("mock solr doc")
      expect(subject.policy_permissions_doc(@policy.pid)).to eq "mock solr doc"
      expect(subject.policy_permissions_doc(@policy.pid)).to eq "mock solr doc"
      expect(subject.policy_permissions_doc(@policy.pid)).to eq "mock solr doc"
    end
  end
  describe "test_edit_from_policy" do
    context "public user" do
      it "should return false" do
        allow(subject).to receive(:user_groups).and_return(["public"])
        expect(subject.test_edit_from_policy(@asset.pid)).to be false
      end
    end
    context "registered user" do
      it "should return false" do
        expect(subject.user_groups).to include("registered")
        expect(subject.test_edit_from_policy(@asset.pid)).to be false
      end
    end
    context "user with policy read access only" do
      it "should return false" do
        allow(subject.current_user).to receive(:user_key).and_return("nero")
        expect(subject.test_edit_from_policy(@asset.pid)).to be false
      end
    end
    context "user with policy edit access" do
      it "should return true" do
        allow(subject.current_user).to receive(:user_key).and_return("julius_caesar")
        expect(subject.test_edit_from_policy(@asset.pid)).to be true
      end
    end
    context "user in group with policy read access" do
      it "should return false" do
        allow(subject).to receive(:user_groups).and_return(["africana-faculty"])
        expect(subject.test_edit_from_policy(@asset.pid)).to be false
      end
    end
    context "user in group with policy edit access" do
      it "should return true" do
        allow(subject).to receive(:user_groups).and_return(["cool_kids"])
        expect(subject.test_edit_from_policy(@asset.pid)).to be true
      end
    end
  end
  describe "test_read_from_policy" do
    context "public user" do
      it "should return false" do
        allow(subject).to receive(:user_groups).and_return(["public"])
        expect(subject.test_read_from_policy(@asset.pid)).to be false
      end
    end
    context "registered user" do
      it "should return false" do
        expect(subject.user_groups).to include("registered")
        expect(subject.test_read_from_policy(@asset.pid)).to be false
      end
    end
    context "user with policy read access only" do
      it "should return false" do
        allow(subject.current_user).to receive(:user_key).and_return("nero")
        expect(subject.test_read_from_policy(@asset.pid)).to be true
      end
    end
    context "user with policy edit access" do
      it "should return true" do
        allow(subject.current_user).to receive(:user_key).and_return("julius_caesar")
        expect(subject.test_read_from_policy(@asset.pid)).to be true
      end
    end
    context "user in group with policy read access" do
      it "should return false" do
        allow(subject).to receive(:user_groups).and_return(["africana-faculty"])
        expect(subject.test_read_from_policy(@asset.pid)).to be true
      end
    end
    context "user in group with policy edit access" do
      it "should return true" do
        allow(subject).to receive(:user_groups).and_return(["cool_kids"])
        expect(subject.test_read_from_policy(@asset.pid)).to be true
      end
    end
  end
  describe "edit_groups_from_policy" do
    it "should retrieve the list of groups with edit access from the policy" do
      result = subject.edit_groups_from_policy(@policy.pid)
      expect(result.length).to eq 2
      expect(result).to include("cool_kids","in_crowd")
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
      expect(result.length).to eq 3
      expect(result).to include("cool_kids", "in_crowd", "africana-faculty")
    end
  end
  describe "read_persons_from_policy" do
    it "should retrieve the list of individuals with read access from the policy" do
      expect(subject.read_users_from_policy(@policy.pid)).to eq ["julius_caesar","nero"]
    end
  end
end
