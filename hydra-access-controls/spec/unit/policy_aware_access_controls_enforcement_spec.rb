require 'spec_helper'

describe Hydra::PolicyAwareAccessControlsEnforcement do
  before(:all) do
    class PolicyMockController
      include Hydra::AccessControlsEnforcement
      include Hydra::PolicyAwareAccessControlsEnforcement
      attr_accessor :params
      
      def current_ability
        @current_ability ||= Ability.new(current_user)
      end

      def session
      end

      delegate :logger, to: :Rails
    end
    
    @sample_policies = []
    # user discover
    policy1 = Hydra::AdminPolicy.new(:pid=>"test:policy1")
    policy1.default_permissions = [{:type=>"user", :access=>"discover", :name=>"sara_student"}]
    policy1.save
    @sample_policies << policy1
    
    # user read
    policy2 = Hydra::AdminPolicy.new(:pid=>"test:policy2")
    policy2.default_permissions = [{:type=>"user", :access=>"read", :name=>"sara_student"}]
    policy2.save
    @sample_policies << policy2
    
    # user edit
    policy3 = Hydra::AdminPolicy.new(:pid=>"test:policy3")
    policy3.default_permissions = [{:type=>"user", :access=>"edit", :name=>"sara_student"}]
    policy3.save
    @sample_policies << policy3
    
    
    # group discover
    policy4 = Hydra::AdminPolicy.new(:pid=>"test:policy4")
    policy4.default_permissions = [{:type=>"group", :access=>"discover", :name=>"africana-104-students"}]
    policy4.save
    @sample_policies << policy4
    
    # group read
    policy5 = Hydra::AdminPolicy.new(:pid=>"test:policy5")
    policy5.default_permissions = [{:type=>"group", :access=>"read", :name=>"africana-104-students"}]
    policy5.save
    @sample_policies << policy5
    
    # group edit
    policy6 = Hydra::AdminPolicy.new(:pid=>"test:policy6")
    policy6.default_permissions = [{:type=>"group", :access=>"edit", :name=>"africana-104-students"}]
    policy6.save
    @sample_policies << policy6
    
    # public discover
    policy7 = Hydra::AdminPolicy.create(:pid => "test:policy7")
    policy7.default_permissions = [{:type=>"group", :access=>"discover", :name=>"public"}]
    policy7.save
    @sample_policies << policy7
  
    # public read
    policy8 = Hydra::AdminPolicy.create(:pid => "test:policy8")
    policy8.default_permissions = [{:type=>"group", :access=>"read", :name=>"public"}]
    policy8.save
    @sample_policies << policy8

    # user discover policies for testing that all are applied when over 10 are applicable
    (9..11).each do |i|
      policy = Hydra::AdminPolicy.create(:pid => "test:policy#{i}")
      policy.default_permissions = [{:type=>"user", :access=>"discover", :name=>"sara_student"}]
      policy.save
      @sample_policies << policy
    end

    # no access 
    policy_no_access = Hydra::AdminPolicy.create(:pid=>"test:policy_no_access")
    @sample_policies << policy_no_access

    @policies_with_access = @sample_policies.select { |p| p.pid != policy_no_access.pid }
  end
  
  after(:all) do
    @sample_policies.each {|p| p.delete }
  end
  
  subject { PolicyMockController.new }
  
  before do
    @solr_parameters = {}
    @user_parameters = {}
    @user = FactoryGirl.build(:sara_student)
  end
  
  describe "policies_with_access" do
    context "Authenticated user" do
      before do
        RoleMapper.stub(:roles).with(@user).and_return(@user.roles)
        subject.stub(:current_user).and_return(@user)
      end
      it "should return the policies that provide discover permissions" do
        @policies_with_access.map {|p| p.pid }.each do |p|
          subject.policies_with_access.should include(p)
        end
        subject.policies_with_access.should_not include("test:policy_no_access")
      end
      it "should allow you to configure which model to use for policies" do
        Hydra.stub(:config).and_return( {:permissions=>{:policy_class => ModsAsset}} )
        ModsAsset.should_receive(:find_with_conditions).and_return([])
        subject.policies_with_access
      end
    end
    context "Anonymous user" do
      before { subject.stub(:current_user).and_return(nil) }
      it "should return the policies that provide discover permissions" do
        subject.policies_with_access.should match_array ["test:policy7", "test:policy8"]
      end
    end
  end
  
  describe "apply_gated_discovery" do
    before do
      RoleMapper.stub(:roles).with(@user).and_return(@user.roles)
      subject.stub(:current_user).and_return(@user)
    end
    it "should include policy-aware query" do
      # stubbing out policies_with_access because solr doesn't always return them in the same order.
      policy_pids = (1..8).map {|n| "test:policy#{n}"}
      subject.should_receive(:policies_with_access).and_return(policy_pids)
      subject.apply_gated_discovery(@solr_parameters, @user_parameters)
      governed_field = ActiveFedora::SolrService.solr_name('is_governed_by', :symbol)
      @solr_parameters[:fq].first.should include(" OR (_query_:\"{!raw f=#{governed_field}}info:fedora/test:policy1\" OR _query_:\"{!raw f=#{governed_field}}info:fedora/test:policy2\" OR _query_:\"{!raw f=#{governed_field}}info:fedora/test:policy3\" OR _query_:\"{!raw f=#{governed_field}}info:fedora/test:policy4\" OR _query_:\"{!raw f=#{governed_field}}info:fedora/test:policy5\" OR _query_:\"{!raw f=#{governed_field}}info:fedora/test:policy6\" OR _query_:\"{!raw f=#{governed_field}}info:fedora/test:policy7\" OR _query_:\"{!raw f=#{governed_field}}info:fedora/test:policy8\")")
    end
    it "should not change anything if there are no clauses to add" do
      subject.stub(:policy_clauses).and_return(nil)
      subject.apply_gated_discovery(@solr_parameters, @user_parameters)
      @solr_parameters[:fq].first.should_not include(" OR (#{ActiveFedora::SolrService.solr_name('is_governed_by', :symbol)}:info\\:fedora\\/test\\:policy1 OR #{ActiveFedora::SolrService.solr_name('is_governed_by', :symbol)}:info\\:fedora\\/test\\:policy2 OR #{ActiveFedora::SolrService.solr_name('is_governed_by', :symbol)}:info\\:fedora\\/test\\:policy3 OR #{ActiveFedora::SolrService.solr_name('is_governed_by', :symbol)}:info\\:fedora\\/test\\:policy4 OR #{ActiveFedora::SolrService.solr_name('is_governed_by', :symbol)}:info\\:fedora\\/test\\:policy5 OR #{ActiveFedora::SolrService.solr_name('is_governed_by', :symbol)}:info\\:fedora\\/test\\:policy6 OR #{ActiveFedora::SolrService.solr_name('is_governed_by', :symbol)}:info\\:fedora\\/test\\:policy7 OR #{ActiveFedora::SolrService.solr_name('is_governed_by', :symbol)}:info\\:fedora\\/test\\:policy8)")
    end
  end

  describe "apply_policy_role_permissions" do
    it "should escape slashes in the group names" do
      RoleMapper.stub(:roles).with(@user).and_return(["abc/123","cde/567"])
      subject.stub(:current_user).and_return(@user)
      user_access_filters = subject.apply_policy_group_permissions
      ["edit","discover","read"].each do |type|
        user_access_filters.should include("#{ActiveFedora::SolrService.solr_name("inheritable_#{type}_access_group", Hydra::Datastream::RightsMetadata.indexer )}\:abc\\\/123")
        user_access_filters.should include("#{ActiveFedora::SolrService.solr_name("inheritable_#{type}_access_group", Hydra::Datastream::RightsMetadata.indexer )}\:cde\\\/567")
      end
    end
    it "should escape spaces in the group names" do
      RoleMapper.stub(:roles).with(@user).and_return(["abc 123","cd/e 567"])
      subject.stub(:current_user).and_return(@user)
      user_access_filters = subject.apply_policy_group_permissions
      ["edit","discover","read"].each do |type|
        user_access_filters.should include("#{ActiveFedora::SolrService.solr_name("inheritable_#{type}_access_group", Hydra::Datastream::RightsMetadata.indexer )}\:abc\\ 123")
        user_access_filters.should include("#{ActiveFedora::SolrService.solr_name("inheritable_#{type}_access_group", Hydra::Datastream::RightsMetadata.indexer )}\:cd\\\/e\\ 567")
      end
    end
  end
end
