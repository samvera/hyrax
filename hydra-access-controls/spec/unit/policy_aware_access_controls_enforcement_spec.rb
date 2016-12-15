require 'spec_helper'

describe Hydra::PolicyAwareAccessControlsEnforcement do
  before do
    allow(Devise).to receive(:authentication_keys).and_return(['uid'])

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
    policy1 = Hydra::AdminPolicy.create(id: "test-policy1")
    policy1.default_permissions.create(:type=>"person", :access=>"discover", :name=>"sara_student")
    policy1.save!

    @sample_policies << policy1

    # user read
    policy2 = Hydra::AdminPolicy.create(id: "test-policy2")
    policy2.default_permissions.create(:type=>"person", :access=>"read", :name=>"sara_student")
    policy2.save!
    @sample_policies << policy2

    # user edit
    policy3 = Hydra::AdminPolicy.create(id: "test-policy3")
    policy3.default_permissions.create(:type=>"person", :access=>"edit", :name=>"sara_student")
    policy3.save!
    @sample_policies << policy3


    # group discover
    policy4 = Hydra::AdminPolicy.create(id: "test-policy4")
    policy4.default_permissions.create(:type=>"group", :access=>"discover", :name=>"africana-104-students")
    policy4.save!
    @sample_policies << policy4

    # group read
    policy5 = Hydra::AdminPolicy.create(id: "test-policy5")
    policy5.default_permissions.create(:type=>"group", :access=>"read", :name=>"africana-104-students")
    policy5.save!
    @sample_policies << policy5

    # group edit
    policy6 = Hydra::AdminPolicy.create(id: "test-policy6")
    policy6.default_permissions.create(:type=>"group", :access=>"edit", :name=>"africana-104-students")
    policy6.save!
    @sample_policies << policy6

    # public discover
    policy7 = Hydra::AdminPolicy.create(id: "test-policy7")
    policy7.default_permissions.create(:type=>"group", :access=>"discover", :name=>"public")
    policy7.save!
    @sample_policies << policy7

    # public read
    policy8 = Hydra::AdminPolicy.create(id: "test-policy8")
    policy8.default_permissions.create(:type=>"group", :access=>"read", :name=>"public")
    policy8.save!
    @sample_policies << policy8

    # user discover policies for testing that all are applied when over 10 are applicable
    (9..11).each do |i|
      policy = Hydra::AdminPolicy.create(id: "test-policy#{i}")
      policy.default_permissions.create(:type=>"person", :access=>"discover", :name=>"sara_student")
      policy.save!
      @sample_policies << policy
    end

    # no access
    policy_no_access = Hydra::AdminPolicy.new(id: "test-policy_no_access")
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
        allow(user).to receive(:groups).and_return(["student", "africana-104-students"])
      end

      it "should return the policies that provide discover permissions" do
        @policies_with_access.map {|p| p.id }.each do |p|
          expect(subject.policies_with_access).to include(p)
        end
        expect(subject.policies_with_access).to_not include("test-policy_no_access")
      end

      it "should allow you to configure which model to use for policies" do
        allow(Hydra.config.permissions).to receive(:policy_class).and_return(ModsAsset)
        expect(ModsAsset).to receive(:search_with_conditions).and_return([])
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
    let(:governed_field) { ActiveFedora.index_field_mapper.solr_name('isGovernedBy', :symbol) }
    let(:policy_queries) { @solr_parameters[:fq].first.split(" OR ") }
    before do
      allow(user).to receive(:groups).and_return(["student", "africana-104-students"])
    end

    context "when policies are included" do
      before { subject.apply_gated_discovery(@solr_parameters) }
      
      it "builds a query that includes all the policies" do
        (1..11).each do |p|
          expect(policy_queries).to include(/_query_:\"{!raw f=#{governed_field}}test-policy#{p}\"/)
        end
      end
    end
    
    context "when policies are not included" do
      before do
        allow(subject).to receive(:policy_clauses).and_return(nil)
        subject.apply_gated_discovery(@solr_parameters)
      end
      it "does not include any policies in the query" do
        (1..11).each do |p|
          expect(policy_queries).not_to include(/_query_:\"{!raw f=#{governed_field}}test-policy#{p}\"/)
        end
      end
    end
  end

  describe "apply_policy_role_permissions" do
    before do
      allow(user).to receive(:groups).and_return(groups)
    end
    context "when there are slashes in the group names" do
      let(:groups) { ["abc/123","cde/567"] }
      it "escapes slashes" do
        user_access_filters = subject.apply_policy_group_permissions
        ["edit","discover","read"].each do |type|
          expect(user_access_filters).to include("inheritable_#{type}_access_group_ssim\:abc\\\/123")
          expect(user_access_filters).to include("inheritable_#{type}_access_group_ssim\:cde\\\/567")
        end
      end
    end

    context "when there are spaces in the group names" do
      let(:groups) { ["abc 123","cd/e 567"] }
      it "escapes spaces" do
        user_access_filters = subject.apply_policy_group_permissions
        ["edit","discover","read"].each do |type|
          expect(user_access_filters).to include("inheritable_#{type}_access_group_ssim\:abc\\ 123")
          expect(user_access_filters).to include("inheritable_#{type}_access_group_ssim\:cd\\\/e\\ 567")
        end
      end
    end
  end
end
