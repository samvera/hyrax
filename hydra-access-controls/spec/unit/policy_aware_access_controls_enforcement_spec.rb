require 'spec_helper'

describe Hydra::PolicyAwareAccessControlsEnforcement do
  before do
    class PolicyMockSearchBuilder < Blacklight::SearchBuilder
      include Blacklight::Solr::SearchBuilderBehavior
      include Hydra::AccessControlsEnforcement
      include Hydra::PolicyAwareAccessControlsEnforcement
      attr_accessor :params

      def initialize(current_ability)
        @current_ability = current_ability
      end

      def current_ability
        @current_ability
      end

      def session
      end

      delegate :logger, to: :Rails
    end
    @sample_policies = []
    # user discover
    policy1 = Hydra::AdminPolicy.create("test-policy1")
    policy1.default_permissions.create(:type=>"person", :access=>"discover", :name=>"sara_student")
    policy1.save!

    @sample_policies << policy1

    # user read
    policy2 = Hydra::AdminPolicy.create("test-policy2")
    policy2.default_permissions.create(:type=>"person", :access=>"read", :name=>"sara_student")
    policy2.save!
    @sample_policies << policy2

    # user edit
    policy3 = Hydra::AdminPolicy.create("test-policy3")
    policy3.default_permissions.create(:type=>"person", :access=>"edit", :name=>"sara_student")
    policy3.save!
    @sample_policies << policy3


    # group discover
    policy4 = Hydra::AdminPolicy.create("test-policy4")
    policy4.default_permissions.create(:type=>"group", :access=>"discover", :name=>"africana-104-students")
    policy4.save!
    @sample_policies << policy4

    # group read
    policy5 = Hydra::AdminPolicy.create("test-policy5")
    policy5.default_permissions.create(:type=>"group", :access=>"read", :name=>"africana-104-students")
    policy5.save!
    @sample_policies << policy5

    # group edit
    policy6 = Hydra::AdminPolicy.create("test-policy6")
    policy6.default_permissions.create(:type=>"group", :access=>"edit", :name=>"africana-104-students")
    policy6.save!
    @sample_policies << policy6

    # public discover
    policy7 = Hydra::AdminPolicy.create("test-policy7")
    policy7.default_permissions.create(:type=>"group", :access=>"discover", :name=>"public")
    policy7.save!
    @sample_policies << policy7

    # public read
    policy8 = Hydra::AdminPolicy.create("test-policy8")
    policy8.default_permissions.create(:type=>"group", :access=>"read", :name=>"public")
    policy8.save!
    @sample_policies << policy8

    # user discover policies for testing that all are applied when over 10 are applicable
    (9..11).each do |i|
      policy = Hydra::AdminPolicy.create("test-policy#{i}")
      policy.default_permissions.create(:type=>"person", :access=>"discover", :name=>"sara_student")
      policy.save!
      @sample_policies << policy
    end

    # no access
    policy_no_access = Hydra::AdminPolicy.new("test-policy_no_access")
    policy_no_access.save!

    @sample_policies << policy_no_access
    @policies_with_access = @sample_policies.select { |p| p.id != policy_no_access.id }
  end

  let(:current_ability) { Ability.new(user) }
  subject { PolicyMockSearchBuilder.new(current_ability) }
  let(:user) { FactoryGirl.build(:sara_student) }

  before do
    @solr_parameters = {}
  end

  describe "policies_with_access" do
    context "Authenticated user" do
      before do
        allow(RoleMapper).to receive(:roles).with(user).and_return(user.roles)
      end

      it "should return the policies that provide discover permissions" do
        @policies_with_access.map {|p| p.id }.each do |p|
          expect(subject.policies_with_access).to include(p)
        end
        expect(subject.policies_with_access).to_not include("test-policy_no_access")
      end

      it "should allow you to configure which model to use for policies" do
        allow(Hydra.config.permissions).to receive(:policy_class).and_return(ModsAsset)
        expect(ModsAsset).to receive(:find_with_conditions).and_return([])
        subject.policies_with_access
      end
    end
    context "Anonymous user" do
      let(:user) { nil }
      it "should return the policies that provide discover permissions" do
        expect(subject.policies_with_access).to match_array ["test-policy7", "test-policy8"]
      end
    end
  end

  describe "apply_gated_discovery" do
    before do
      allow(RoleMapper).to receive(:roles).with(user).and_return(user.roles)
    end
    let(:governed_field) { ActiveFedora::SolrQueryBuilder.solr_name('isGovernedBy', :symbol) }

    it "should include policy-aware query" do
      # stubbing out policies_with_access because solr doesn't always return them in the same order.
      policy_ids = (1..8).map {|n| "policies/#{n}"}
      expect(subject).to receive(:policies_with_access).and_return(policy_ids)
      subject.apply_gated_discovery(@solr_parameters)
      expect(@solr_parameters[:fq].first).to include(" OR (_query_:\"{!raw f=#{governed_field}}policies/1\" OR _query_:\"{!raw f=#{governed_field}}policies/2\" OR _query_:\"{!raw f=#{governed_field}}policies/3\" OR _query_:\"{!raw f=#{governed_field}}policies/4\" OR _query_:\"{!raw f=#{governed_field}}policies/5\" OR _query_:\"{!raw f=#{governed_field}}policies/6\" OR _query_:\"{!raw f=#{governed_field}}policies/7\" OR _query_:\"{!raw f=#{governed_field}}policies/8\")")
    end

    it "should not change anything if there are no clauses to add" do
      allow(subject).to receive(:policy_clauses).and_return(nil)
      subject.apply_gated_discovery(@solr_parameters)
      expect(@solr_parameters[:fq].first).not_to include(" OR (_query_:\"{!raw f=#{governed_field}}policies/1\" OR _query_:\"{!raw f=#{governed_field}}policies/2\" OR _query_:\"{!raw f=#{governed_field}}policies/3\" OR _query_:\"{!raw f=#{governed_field}}policies/4\" OR _query_:\"{!raw f=#{governed_field}}policies/5\" OR _query_:\"{!raw f=#{governed_field}}policies/6\" OR _query_:\"{!raw f=#{governed_field}}policies/7\" OR _query_:\"{!raw f=#{governed_field}}policies/8\")")
    end
  end

  describe "apply_policy_role_permissions" do
    it "should escape slashes in the group names" do
      allow(RoleMapper).to receive(:roles).with(user).and_return(["abc/123","cde/567"])
      user_access_filters = subject.apply_policy_group_permissions
      ["edit","discover","read"].each do |type|
        expect(user_access_filters).to include("inheritable_#{type}_access_group_ssim\:abc\\\/123")
        expect(user_access_filters).to include("inheritable_#{type}_access_group_ssim\:cde\\\/567")
      end
    end

    it "should escape spaces in the group names" do
      allow(RoleMapper).to receive(:roles).with(user).and_return(["abc 123","cd/e 567"])
      user_access_filters = subject.apply_policy_group_permissions
      ["edit","discover","read"].each do |type|
        expect(user_access_filters).to include("inheritable_#{type}_access_group_ssim\:abc\\ 123")
        expect(user_access_filters).to include("inheritable_#{type}_access_group_ssim\:cd\\\/e\\ 567")
      end
    end
  end
end
