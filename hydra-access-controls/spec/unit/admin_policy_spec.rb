require 'spec_helper'

describe Hydra::AdminPolicy do
  its(:defaultRights) { should be_kind_of Hydra::Datastream::InheritableRightsMetadata}
  its(:rightsMetadata) { should be_kind_of Hydra::Datastream::RightsMetadata}
  its(:descMetadata) { should be_kind_of ActiveFedora::QualifiedDublinCoreDatastream}

  describe "when setting attributes" do
    before do
      subject.title = "My title" 
      subject.description = "My description" 
      subject.license_title = "My license" 
      subject.license_description = "My license desc" 
      subject.license_url = "My url" 
    end
    its(:title) { should == "My title"}
    its(:description) { should == "My description"}
    its(:license_title) { should == "My license"}
    its(:license_description) { should == "My license desc"}
    its(:license_url) { should == "My url"}
  end
    

  describe "to_solr" do
    subject { Hydra::AdminPolicy.new(:title=>"Foobar").to_solr }
    it "should have title_ssim" do
      subject[ActiveFedora::SolrService.solr_name('title', type: :string)].should == "Foobar"
    end
  end

  describe "updating default permissions" do
    it "should create new group permissions" do
      subject.default_permissions = [{:name=>'group1', :access=>'discover', :type=>'group'}]
      subject.default_permissions.should == [{:type=>'group', :access=>'discover', :name=>'group1'}]
    end
    it "should create new user permissions" do
      subject.default_permissions = [{:name=>'user1', :access=>'discover', :type=>'user'}]
      subject.default_permissions.should == [{:type=>'user', :access=>'discover', :name=>'user1'}]
    end
    it "should not replace existing groups" do
      subject.default_permissions = [{:name=>'group1', :access=>'discover', :type=>'group'}]
      subject.default_permissions = [{:name=>'group2', :access=>'discover', :type=>'group'}]
      subject.default_permissions.should == [{:type=>'group', :access=>'discover', :name=>'group1'},
                                   {:type=>'group', :access=>'discover', :name=>'group2'}]
    end
    it "should not replace existing users" do
      subject.default_permissions = [{:name=>'user1', :access=>'discover', :type=>'user'}]
      subject.default_permissions = [{:name=>'user2', :access=>'discover', :type=>'user'}]
      subject.default_permissions.should == [{:type=>'user', :access=>'discover', :name=>'user1'},
                                   {:type=>'user', :access=>'discover', :name=>'user2'}]
    end
    it "should update permissions on existing users" do
      subject.default_permissions = [{:name=>'user1', :access=>'discover', :type=>'user'}]
      subject.default_permissions = [{:name=>'user1', :access=>'edit', :type=>'user'}]
      subject.default_permissions.should == [{:type=>'user', :access=>'edit', :name=>'user1'}]
    end
    it "should update permissions on existing groups" do
      subject.default_permissions = [{:name=>'group1', :access=>'discover', :type=>'group'}]
      subject.default_permissions = [{:name=>'group1', :access=>'edit', :type=>'group'}]
      subject.default_permissions.should == [{:type=>'group', :access=>'edit', :name=>'group1'}]
    end
    it "should assign user permissions when :type == 'person'" do
      subject.default_permissions = [{:name=>'user1', :access=>'discover', :type=>'person'}]
      subject.default_permissions.should == [{:type=>'user', :access=>'discover', :name=>'user1'}]
    end
    it "should raise an ArgumentError when the :type hashkey is invalid" do
      expect{subject.default_permissions = [{:name=>'user1', :access=>'read', :type=>'foo'}]}.to raise_error(ArgumentError)
    end
  end
  
  describe "Inheritable rights" do
    before do
      @policy = Hydra::AdminPolicy.new
      @policy.default_permissions = [{:name=>"africana-faculty", :access=>"edit", :type=>"group"}, {:name=>"cool-kids", :access=>"edit", :type=>"group"}, {:name=>"julius_caesar", :access=>"edit", :type=>"user"}]
      @policy.default_permissions = [{:name=>"slightlycoolkids", :access=>"read", :type=>"group"}, {:name=>"nero", :access=>"read", :type=>"user"}]
      @policy.default_permissions = [{:name=>"posers", :access=>"discover", :type=>"group"}, {:name=>"constantine", :access=>"discover", :type=>"user"}]
      @policy.defaultRights.embargo_release_date = "2102-10-01"
    end

    describe "to_solr" do
      subject {@policy.to_solr}
      it "should not affect normal solr permissions fields" do    
        subject.should_not have_key( Hydra.config[:permissions][:discover][:group] ) 
        subject.should_not have_key( Hydra.config[:permissions][:discover][:individual] )
        subject.should_not have_key( Hydra.config[:permissions][:read][:group] )
        subject.should_not have_key( Hydra.config[:permissions][:read][:individual] )
        subject.should_not have_key( Hydra.config[:permissions][:edit][:group] )
        subject.should_not have_key( Hydra.config[:permissions][:edit][:individual] )
        subject.should_not have_key( Hydra.config[:permissions][:embargo_release_date] )
      end
      it "should provide prefixed/inherited solr permissions fields" do
        subject[Hydra.config[:permissions][:inheritable][:discover][:group] ].should == ["posers"]
        subject[Hydra.config[:permissions][:inheritable][:discover][:individual] ].should == ["constantine"]
        subject[Hydra.config[:permissions][:inheritable][:read][:group] ].should == ["slightlycoolkids"]
        subject[Hydra.config[:permissions][:inheritable][:read][:individual] ].should == ["nero"]
        inheritable_group = Hydra.config[:permissions][:inheritable][:edit][:group]
        subject[inheritable_group].length.should == 2
        subject[inheritable_group].should include("africana-faculty", "cool-kids")

        subject[Hydra.config[:permissions][:inheritable][:edit][:individual] ].should == ["julius_caesar"]
        expect(subject[Hydra.config[:permissions][:inheritable][:embargo_release_date] ]).to eq Date.parse("2102-10-01").to_time.utc.iso8601
      end
    end

  end

  #
  # Policy-based Access Controls
  #
  describe "When accessing assets with Policies associated" do
    before do
      @user = FactoryGirl.build(:martia_morocco)
      RoleMapper.stub(:roles).with(@user).and_return(@user.roles)
    end
    before(:all) do
      class TestAbility
        include Hydra::PolicyAwareAbility
      end
    end

    after(:all) do
      Object.send(:remove_const, :TestAbility)
    end
    subject { TestAbility.new(@user) }
    context "Given a policy grants read access to a group I belong to" do
      before do
        @policy = Hydra::AdminPolicy.new
        @policy.default_permissions = [{:type=>"group", :access=>"read", :name=>"africana-faculty"}]
        @policy.save
      end
      after { @policy.delete }
    	context "And a subscribing asset does not grant access" do
    	  before do
          @asset = ModsAsset.new()
          @asset.admin_policy = @policy
          @asset.save
        end
        after { @asset.delete }
    		it "Then I should be able to view the asset" do
    		  subject.can?(:read, @asset).should be_true
  		  end
        it "Then I should not be able to edit, update and destroy the asset" do
          subject.can?(:edit, @asset).should be_false
          subject.can?(:update, @asset).should be_false
          subject.can?(:destroy, @asset).should be_false
        end
      end
    end
    context "Given a policy grants edit access to a group I belong to" do
      before do
        @policy = Hydra::AdminPolicy.new
        @policy.default_permissions = [{:type=>"group", :access=>"edit", :name=>"africana-faculty"}]
        @policy.save
      end
      after { @policy.delete }
    	context "And a subscribing asset does not grant access" do
    	  before do
          @asset = ModsAsset.new()
          @asset.admin_policy = @policy
          @asset.save
        end
        after { @asset.delete }
    		it "Then I should be able to view the asset" do
    		  subject.can?(:read, @asset).should be_true
  		  end
    		it "Then I should be able to edit/update/destroy the asset" do
          subject.can?(:edit, @asset).should be_true
          subject.can?(:update, @asset).should be_true
          subject.can?(:destroy, @asset).should be_true
        end
  		end
    	context "And a subscribing asset grants read access to me as an individual" do
    	  before do
          @asset = ModsAsset.new()
          @asset.read_users = [@user.uid]
          @asset.admin_policy = @policy
          @asset.save
        end
        after { @asset.delete }
    		it "Then I should be able to view the asset" do
    		  subject.can?(:read, @asset).should be_true
  		  end
        it "Then I should be able to edit/update/destroy the asset" do
          subject.can?(:edit, @asset).should be_true
          subject.can?(:update, @asset).should be_true
          subject.can?(:destroy, @asset).should be_true
        end
      end
    end

    context "Given a policy does not grant access to any group I belong to" do
      before do
        @policy = Hydra::AdminPolicy.new
        @policy.save
      end
      after { @policy.delete }
      context "And a subscribing asset does not grant access" do
        before do
          @asset = ModsAsset.new()
          @asset.admin_policy = @policy
          @asset.save
        end
        after { @asset.delete }
  		  it "Then I should not be able to view the asset" do
    		  subject.can?(:read, @asset).should be_false
  		  end
        it "Then I should not be able to edit/update/destroy the asset" do
          subject.can?(:edit, @asset).should be_false
          subject.can?(:update, @asset).should be_false
          subject.can?(:destroy, @asset).should be_false
        end
      end
      context "And a subscribing asset grants read access to me as an individual" do
        before do
          @asset = ModsAsset.new()
          @asset.read_users = [@user.uid]
          @asset.admin_policy = @policy
          @asset.save
        end
        after { @asset.delete }
  		  it "Then I should be able to view the asset" do
    		  subject.can?(:read, @asset).should be_true
  		  end
        it "Then I should not be able to edit/update/destroy the asset" do
          subject.can?(:edit, @asset).should be_false
          subject.can?(:update, @asset).should be_false
          subject.can?(:destroy, @asset).should be_false
        end
      end
    end
  end

end
