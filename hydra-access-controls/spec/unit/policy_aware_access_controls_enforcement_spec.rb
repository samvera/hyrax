require 'spec_helper'

describe Hydra::PolicyAwareAccessControlsEnforcement do
  before do
    class Rails; end
    Rails.stub(:root).and_return('spec/support')
    Rails.stub(:env).and_return('test')
  end
  before(:all) do
    class MockController
      include Hydra::AccessControlsEnforcement
      include Hydra::PolicyAwareAccessControlsEnforcement
      attr_accessor :params
      
      def user_key
        current_user.user_key
      end

      def session
      end
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
    
    # no access 
    policy7 = Hydra::AdminPolicy.create(:pid=>"test:policy7")
    @sample_policies << policy7
  
    @policies_with_access = @sample_policies.select { |p| p.pid != policy7.pid }
  end
  
  after(:all) do
    @policies.access.each {|p| p.delete }
  end
  
  subject { MockController.new }
  
  before do
    @solr_parameters = {}
    @user_parameters = {}
    @user = FactoryGirl.build(:sara_student)
    RoleMapper.stub(:roles).with(@user.user_key).and_return(@user.roles)
    subject.stub(:current_user).and_return(@user)
  end
  
  describe "policies_with_access" do
    it "should return the policies that provide discover permissions" do
      @policies_with_access.map {|p| p.pid }.each do |p|
        subject.policies_with_access.should include(p)
      end
    end
    it "should return the policies that provide discover permissions" do
        subject.policies_with_access.should_not include("test:policy7")
    end
    it "should allow you to configure which model to use for policies" do
      Hydra.stub(:config).and_return( {:permissions=>{:policy_class => ModsAsset}} )
      ModsAsset.should_receive(:find_with_conditions).and_return([])
      subject.policies_with_access
    end
  end
  
  describe "apply_gated_discovery" do
    it "should include policy-aware query" do
      subject.apply_gated_discovery(@solr_parameters, @user_parameters)
      @solr_parameters[:fq].first.should include(" OR (is_governed_by_s:info\\:fedora/test\\:policy1 OR is_governed_by_s:info\\:fedora/test\\:policy2 OR is_governed_by_s:info\\:fedora/test\\:policy3 OR is_governed_by_s:info\\:fedora/test\\:policy4 OR is_governed_by_s:info\\:fedora/test\\:policy5 OR is_governed_by_s:info\\:fedora/test\\:policy6)")
    end
    it "should not change anything if there are no clauses to add" do
      subject.stub(:policy_clauses).and_return(nil)
      subject.apply_gated_discovery(@solr_parameters, @user_parameters)
      @solr_parameters[:fq].first.should_not include(" OR (is_governed_by_s:info\\:fedora/test\\:policy1 OR is_governed_by_s:info\\:fedora/test\\:policy2 OR is_governed_by_s:info\\:fedora/test\\:policy3 OR is_governed_by_s:info\\:fedora/test\\:policy4 OR is_governed_by_s:info\\:fedora/test\\:policy5 OR is_governed_by_s:info\\:fedora/test\\:policy6)")
    end
  end
end