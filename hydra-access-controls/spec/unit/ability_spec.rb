require 'spec_helper'

describe Ability do
  before do
    class Rails; end
    Rails.stub(:root).and_return('spec/support')
    Rails.stub(:env).and_return('test')
    Hydra.stub(:config).and_return({
      :permissions=>{
        :catchall => "access_t",
        :discover => {:group =>"discover_access_group_t", :individual=>"discover_access_person_t"},
        :read => {:group =>"read_access_group_t", :individual=>"read_access_person_t"},
        :edit => {:group =>"edit_access_group_t", :individual=>"edit_access_person_t"},
        :owner => "depositor_t",
        :embargo_release_date => "embargo_release_date_dt",
      
        :inheritable => {
          :catchall => "inheritable_access_t",
          :discover => {:group =>"inheritable_discover_access_group_t", :individual=>"inheritable_discover_access_person_t"},
          :read => {:group =>"inheritable_read_access_group_t", :individual=>"inheritable_read_access_person_t"},
          :edit => {:group =>"inheritable_edit_access_group_t", :individual=>"inheritable_edit_access_person_t"},
          :owner => "inheritable_depositor_t",
          :embargo_release_date => "inheritable_embargo_release_date_dt"
        }
    }})
  end

  context "for a not-signed in user" do
    before do
      User.any_instance.stub(:email).and_return(nil)
      User.any_instance.stub(:new_record?).and_return(true)
      User.any_instance.stub(:is_being_superuser?).and_return(false)
    end
    subject { Ability.new(nil) }
    it "should call custom_permissions" do
      Ability.any_instance.should_receive(:custom_permissions)
      subject.can?(:delete, 7)
    end
    it "should not be able to create objects" do
      subject.can?(:create, :any).should be_false
    end
  end
  context "for a signed in user" do
    before do
      @user = FactoryGirl.build(:registered_user)
    end
    subject { Ability.new(@user) }
    it "should be able to create objects" do
      subject.can?(:create, :any).should be_true
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
        subject.can?(:read, @asset).should be_true
      end
      it "should not be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be_false
        subject.can?(:update, @asset).should be_false
        subject.can?(:destroy, @asset).should be_false
      end
    end
    context "Then a registered user" do
      before do
        @user = FactoryGirl.build(:registered_user)
      end
      subject { Ability.new(@user) }
      it "should be able to view the asset" do
        subject.can?(:read, @asset).should be_true
      end
      it "should not be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be_false
        subject.can?(:update, @asset).should be_false
        subject.can?(:destroy, @asset).should be_false
      end
    end
  end
  
  describe "Given an asset with no custom access set" do
    before do
      @asset = FactoryGirl.build(:default_access_asset)
      @asset.save
    end
    context "Then a not-signed-in user" do
      before do
        @user = User.new
        @user.new_record = true
      end
      subject { Ability.new(@user) }
      it "should not be able to view the asset" do
        subject.can?(:read, @asset).should be_false
      end
      it "should not be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be_false
        subject.can?(:update, @asset).should be_false
        subject.can?(:destroy, @asset).should be_false
      end
    end
    context "Then a registered user" do
      before do
        @user = FactoryGirl.build(:registered_user)
      end
      subject { Ability.new(@user) }
      it "should not be able to view the asset" do
        subject.can?(:read, @asset).should be_false
      end
      it "should not be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be_false
        subject.can?(:update, @asset).should be_false
        subject.can?(:destroy, @asset).should be_false
      end
    end
    context "Then the Creator" do
      before do
        @user = FactoryGirl.build(:joe_creator)
      end
      subject { Ability.new(@user) }

      it "should be able to view the asset" do
        subject.can?(:read, @asset).should be_true
      end
      it "should be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be_true
        subject.can?(:update, @asset).should be_true
        subject.can?(:destroy, @asset).should be_true
      end
      it "should not be able to see the admin view of the asset" do
        subject.can?(:admin, @asset).should be_false
      end
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
        subject.can?(:read, @asset).should be_true
      end
      it "should not be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be_false
        subject.can?(:update, @asset).should be_false
        subject.can?(:destroy, @asset).should be_false
      end
      it "should not be able to see the admin view of the asset" do
        subject.can?(:admin, @asset).should be_false
      end
    end
  end

  describe "Given an asset with collaborator" do
    before do
      @asset = FactoryGirl.build(:org_read_access_asset)
      @asset.save
    end
    context "Then a collaborator with edit access" do
      before do
        @user = FactoryGirl.build(:calvin_collaborator)
      end
      subject { Ability.new(@user) }

      it "should be able to view the asset" do
        subject.can?(:read, @asset).should be_true
      end
      it "should be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be_true
        subject.can?(:update, @asset).should be_true
        subject.can?(:destroy, @asset).should be_true
      end
      it "should not be able to see the admin view of the asset" do
        subject.can?(:admin, @asset).should be_false
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
        subject.can?(:read, @asset).should be_false
      end
      it "should not be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be_false
        subject.can?(:update, @asset).should be_false
        subject.can?(:destroy, @asset).should be_false
      end
      it "should not be able to see the admin view of the asset" do
        subject.can?(:admin, @asset).should be_false
      end
    end
    context "Then someone whose role/group has read access" do
      before do
        @user = FactoryGirl.build(:martia_morocco)
        RoleMapper.stub(:roles).with(@user.user_key).and_return(@user.roles)
      end
      subject { Ability.new(@user) }

      it "should be able to view the asset" do
        subject.can?(:read, @asset).should be_true
      end
      it "should not be able to edit, update and destroy the asset" do
        subject.can?(:edit, @asset).should be_false
        subject.can?(:update, @asset).should be_false
        subject.can?(:destroy, @asset).should be_false
      end
      it "should not be able to see the admin view of the asset" do
        subject.can?(:admin, @asset).should be_false
      end
    end
  end

  describe "a user" do
    before do
      @user = FactoryGirl.create(:staff)
    end
    subject { Ability.new(@user) }

    it "should be able to create admin policies" do
      subject.can?(:create, Hydra::AdminPolicy).should be_true
    end

  end

  #
  # Policy-based Access Controls
  #
  describe "When accessing assets with Policies associated" do
    before do
      @user = FactoryGirl.build(:martia_morocco)
      RoleMapper.stub(:roles).with(@user.user_key).and_return(@user.roles)
    end
    subject { Ability.new(@user) }
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
