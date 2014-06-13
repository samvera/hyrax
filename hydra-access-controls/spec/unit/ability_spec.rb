require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  describe "class methods" do
    subject { Ability }
    its(:read_group_field) { should == 'read_access_group_ssim'}
    its(:read_user_field) { should == 'read_access_person_ssim'}
    its(:edit_group_field) { should == 'edit_access_group_ssim'}
    its(:edit_user_field) { should == 'edit_access_person_ssim'}
  end

  context "for a not-signed in user" do
    before do
      User.any_instance.stub(:email).and_return(nil)
      User.any_instance.stub(:new_record?).and_return(true)
    end
    subject { Ability.new(nil) }
    it "should call custom_permissions" do
      Ability.any_instance.should_receive(:custom_permissions)
      subject.can?(:delete, 7)
    end
    it "should not be able to create ActiveFedora::Base objects" do
      subject.should_not be_able_to(:create, ActiveFedora::Base)
    end
  end

  context "for a signed in user" do
    before do
      @user = FactoryGirl.build(:registered_user)
    end
    subject { Ability.new(@user) }
    it "should not be able to create ActiveFedora::Base objects" do
      subject.should_not be_able_to(:create, ActiveFedora::Base)
    end
  end


# NOTES: 
#   See spec/requests/... for test coverage describing WHAT should appear on a page based on access permissions
#   Test coverage for discover permission is in spec/requests/gated_discovery_spec.rb
  
  describe "Given an asset that has been made publicly available (ie. open access)" do
    before do
      @asset = FactoryGirl.build(:open_access_asset)
      @asset.save
    end
    context "Then a not-signed-in user" do
      before do
        @user = User.new
        @user.new_record = true
      end
      subject { Ability.new(nil) }
      it "should be able to view the asset" do
        subject.can?(:read, @asset).should be true
      end
      it "should not be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be false
        subject.can?(:update, @asset).should be false
        subject.can?(:destroy, @asset).should be false
      end
    end
    context "Then a registered user" do
      before do
        @user = FactoryGirl.build(:registered_user)
      end
      subject { Ability.new(@user) }
      it "should be able to view the asset" do
        subject.can?(:read, @asset).should be true
      end
      it "should not be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be false
        subject.can?(:update, @asset).should be false
        subject.can?(:destroy, @asset).should be false
      end
    end
  end
  
  describe "Given an asset with no custom access set" do
    let(:asset) { FactoryGirl.create(:default_access_asset) }
    let(:solr_doc) { SolrDocument.new(asset.rightsMetadata.to_solr.merge(id: asset.pid)) }
    context "Then a not-signed-in user" do
      let(:user) { User.new.tap {|u| u.new_record = true } }
      subject { Ability.new(user) }
      it { should_not be_able_to(:read, asset) }
      it { should_not be_able_to(:edit, asset) }
      it { should_not be_able_to(:update, asset) }
      it { should_not be_able_to(:destroy, asset) }
    end
    context "Then a registered user" do
      subject { Ability.new(FactoryGirl.build(:registered_user)) }
      it { should_not be_able_to(:read, asset) }
      it { should_not be_able_to(:edit, asset) }
      it { should_not be_able_to(:update, asset) }
      it { should_not be_able_to(:destroy, asset) }
    end
    context "Then the Creator" do
      subject { Ability.new(FactoryGirl.build(:joe_creator)) }
      it { should     be_able_to(:read, asset) }
      it { should     be_able_to(:edit, asset) }
      it { should     be_able_to(:edit, solr_doc) }
      it { should     be_able_to(:update, asset) }
      it { should     be_able_to(:update, solr_doc) }
      it { should     be_able_to(:destroy, asset) }
      it { should     be_able_to(:destroy, solr_doc) }
      it { should_not be_able_to(:admin, asset) }
    end
  end

  describe "Given an asset which registered users have read access to" do
    before do
      @asset = FactoryGirl.build(:org_read_access_asset)
      @asset.save
    end
    context "The a registered user" do
      before do
        @user = FactoryGirl.build(:registered_user)
      end
      subject { Ability.new(@user) }

      it "should be able to view the asset" do
        subject.can?(:read, @asset).should be true
      end
      it "should not be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be false
        subject.can?(:update, @asset).should be false
        subject.can?(:destroy, @asset).should be false
      end
      it "should not be able to see the admin view of the asset" do
        subject.can?(:admin, @asset).should be false
      end
    end
  end

  describe "Given an asset with collaborator" do
    before { @asset = FactoryGirl.create(:group_edit_asset) }
    after { @asset.destroy }
    context "Then a collaborator with edit access (user permision)" do
      before do
        @user = FactoryGirl.build(:calvin_collaborator)
      end
      subject { Ability.new(@user) }

      it "should be able to view the asset" do
        subject.can?(:read, @asset).should be true
      end
      it "should be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be true
        subject.can?(:update, @asset).should be true
        subject.can?(:destroy, @asset).should be true
      end
      it "should not be able to see the admin view of the asset" do
        subject.can?(:admin, @asset).should be false
      end
    end
    context "Then a collaborator with edit access (group permision)" do
      before do
        @user = FactoryGirl.build(:martia_morocco)
        RoleMapper.stub(:roles).with(@user).and_return(@user.roles)
      end
      subject { Ability.new(@user) }

      it "should be able to view the asset" do
        subject.can?(:read, @asset).should be true
      end
    end
  end

  describe "Given an asset where dept can read & registered users can discover" do
    before do
      @asset = FactoryGirl.build(:dept_access_asset)
      @asset.save
    end
    context "Then a registered user" do
      before do
        @user = FactoryGirl.build(:registered_user)
      end
      subject { Ability.new(@user) }

      it "should not be able to view the asset" do
        subject.can?(:read, @asset).should be false
      end
      it "should not be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be false
        subject.can?(:update, @asset).should be false
        subject.can?(:destroy, @asset).should be false
      end
      it "should not be able to see the admin view of the asset" do
        subject.can?(:admin, @asset).should be false
      end
    end
    context "Then someone whose role/group has read access" do
      before do
        @user = FactoryGirl.build(:martia_morocco)
        RoleMapper.stub(:roles).with(@user).and_return(@user.roles)
      end
      subject { Ability.new(@user) }

      it "should be able to view the asset" do
        subject.can?(:read, @asset).should be true
      end
      it "should not be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be false
        subject.can?(:update, @asset).should be false
        subject.can?(:destroy, @asset).should be false
      end
      it "should not be able to see the admin view of the asset" do
        subject.can?(:admin, @asset).should be false
      end
    end
  end


  describe "custom method" do
    before do
      class MyAbility
        include Hydra::Ability
        self.ability_logic +=[:setup_my_permissions]

        def setup_my_permissions
          can :accept, ActiveFedora::Base
        end
      end
      @user = FactoryGirl.create(:staff)
    end

    after do
      Object.send(:remove_const, :MyAbility)
    end

    subject { MyAbility.new(@user) }

    it "should be set the custom permission" do
      subject.can?(:accept, ActiveFedora::Base).should be true
    end

  end

  describe "calling ability on two separate objects" do
    before do
      @asset1 = FactoryGirl.create(:org_read_access_asset)
      @asset2 = FactoryGirl.create(:asset)
      @user = FactoryGirl.build(:calvin_collaborator) # has access to @asset1, but not @asset2
    end
    after do
      @asset1.destroy
      @asset2.destroy
    end
    subject { Ability.new(@user) }
    it "should be readable in the first instance and not in the second instance" do
      # We had a bug around this where it keeps returning the access for the first object queried
      subject.can?(:edit, @asset1).should be true  
      subject.can?(:edit, @asset2).should be false  
    end
  end

  describe "download permissions" do
    subject { Ability.new(@user) }
    before do
      @asset = FactoryGirl.create(:asset)
      @user = FactoryGirl.build(:user)
    end
    after { @asset.destroy }
    context "user has read permission on the object" do
      before do
        @asset.read_users = [@user.user_key]
        @asset.save
      end
      it "should permit the user to download the object's datastreams" do
        subject.can?(:read, @asset).should be true
        @asset.datastreams.each_value do |ds|
          subject.can?(:download, ds).should be true
        end
      end
    end
    context "user lacks read permission on the object" do
      it "should not permit the user to download the object's datastreams" do
        subject.can?(:read, @asset).should be false
        @asset.datastreams.each_value do |ds|
          subject.can?(:download, ds).should be false
        end
      end
    end
  end

end
