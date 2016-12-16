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
  end

  let(:policy) do
    Hydra::AdminPolicy.create do |p|
      # Set the inheritable permissions
      p.default_permissions.build [
        { type: "group", access: "read", name: "africana-faculty" },
        { type: "group", access: "edit", name: "cool_kids" },
        { type: "group", access: "edit", name: "in_crowd" },
        { type: "person", access: "read", name: "nero" },
        { type: "person", access: "edit", name: "julius_caesar" }
      ]
    end
  end
  let(:asset) { ModsAsset.create { |a| a.admin_policy = policy } }

  after do
    Object.send(:remove_const, :PolicyAwareClass)
  end

  let(:instance) { PolicyAwareClass.new( User.new ) }

  describe "policy_id_for" do
    let(:policy2) do
      Hydra::AdminPolicy.create do |p|
        # Set the inheritable permissions
        p.default_permissions.build [
          { type: "group", access: "read", name: "untenured-faculty" },
          { type: "group", access: "edit", name: "awesome_kids" },
          { type: "group", access: "edit", name: "bad_crowd" },
          { type: "person", access: "read", name: "constantine" },
          { type: "person", access: "edit", name: "brutus" }
        ]
      end
    end
    let(:asset2) { ModsAsset.create { |a| a.admin_policy = policy2 } }
    let(:asset3) { ModsAsset.create }

    it "retrieves the pid doc for the current object's governing policy" do
      expect(instance.policy_id_for(asset.id)).to eq policy.id
      expect(instance.policy_id_for(asset2.id)).to eq policy2.id
      expect(instance.policy_id_for(asset3.id)).to be_nil
    end
  end

  describe "policy_permissions_doc" do
    it "retrieves the permissions doc for the current object's policy and store for re-use" do
      expect(instance).to receive(:get_permissions_solr_response_for_doc_id).with(policy.id).once.and_return("mock solr doc")
      expect(instance.policy_permissions_doc(policy.id)).to eq "mock solr doc"
      expect(instance.policy_permissions_doc(policy.id)).to eq "mock solr doc"
      expect(instance.policy_permissions_doc(policy.id)).to eq "mock solr doc"
    end
  end

  describe "test_edit_from_policy" do
    context "public user" do
      it "returns false" do
        allow(instance).to receive(:user_groups).and_return(["public"])
        expect(instance.test_edit_from_policy(asset.id)).to be false
      end
    end
    context "registered user" do
      it "returns false" do
        #expect(instance.user_groups).to include("registered")
        expect(instance.test_edit_from_policy(asset.id)).to be false
      end
    end
    context "user with policy read access only" do
      it "returns false" do
        allow(instance.current_user).to receive(:user_key).and_return("nero")
        expect(instance.test_edit_from_policy(asset.id)).to be false
      end
    end
    context "user with policy edit access" do
      it "returns true" do
        allow(instance.current_user).to receive(:user_key).and_return("julius_caesar")
        expect(instance.test_edit_from_policy(asset.id)).to be true
      end
    end
    context "user in group with policy read access" do
      it "returns false" do
        allow(instance).to receive(:user_groups).and_return(["africana-faculty"])
        expect(instance.test_edit_from_policy(asset.id)).to be false
      end
    end
    context "user in group with policy edit access" do
      it "returns true" do
        allow(instance).to receive(:user_groups).and_return(["cool_kids"])
        expect(instance.test_edit_from_policy(asset.id)).to be true
      end
    end
  end

  describe "test_read_from_policy" do
    context "public user" do
      it "returns false" do
        allow(instance).to receive(:user_groups).and_return(["public"])
        expect(instance.test_read_from_policy(asset.id)).to be false
      end
    end

    context "registered user" do
      it "returns false" do
        expect(instance.test_read_from_policy(asset.id)).to be false
      end
    end

    context "user with policy read access only" do
      it "returns false" do
        allow(instance.current_user).to receive(:user_key).and_return("nero")
        expect(instance.test_read_from_policy(asset.id)).to be true
      end
    end

    context "user with policy edit access" do
      it "returns true" do
        allow(instance.current_user).to receive(:user_key).and_return("julius_caesar")
        expect(instance.test_read_from_policy(asset.id)).to be true
      end
    end

    context "user in group with policy read access" do
      it "returns false" do
        allow(instance).to receive(:user_groups).and_return(["africana-faculty"])
        expect(instance.test_read_from_policy(asset.id)).to be true
      end
    end

    context "user in group with policy edit access" do
      it "returns true" do
        allow(instance).to receive(:user_groups).and_return(["cool_kids"])
        expect(instance.test_read_from_policy(asset.id)).to be true
      end
    end
  end

  describe "edit_groups_from_policy" do
    subject { instance.edit_groups_from_policy(policy.id) }

    it "retrieves the list of groups with edit access from the policy" do
      expect(subject).to match_array ["cool_kids", "in_crowd"]
    end
  end

  describe "edit_persons_from_policy" do
    subject do
      instance.edit_users_from_policy(policy.id)
    end

    it "retrieves the list of individuals with edit access from the policy" do
      expect(subject).to eq ["julius_caesar"]
    end
  end

  describe "read_groups_from_policy" do
    subject { instance.read_groups_from_policy(policy.id) }

    it "retrieves the list of groups with read access from the policy" do
      expect(subject).to match_array ["cool_kids", "in_crowd", "africana-faculty"]
    end
  end

  describe "read_users_from_policy" do
    subject { instance.read_users_from_policy(policy.id) }

    it "retrieves the list of individuals with read access from the policy" do
      expect(subject).to eq ["julius_caesar", "nero"]
    end
  end
end
