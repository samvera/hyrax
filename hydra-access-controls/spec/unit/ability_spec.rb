require 'spec_helper'

describe Ability do
  before do
    Hydra.stub(:config).and_return({
      :permissions=>{
        :discover => {:group =>"discover_access_group_ssim", :individual=>"discover_access_person_ssim"},
        :read => {:group =>"read_access_group_ssim", :individual=>"read_access_person_ssim"},
        :edit => {:group =>"edit_access_group_ssim", :individual=>"edit_access_person_ssim"},
        :owner => "depositor_t",
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

  describe "class methods" do
    subject { Ability }
    its(:read_group_field) { should == 'read_access_group_ssim'}
    its(:read_person_field) { should == 'read_access_person_ssim'}
    its(:edit_group_field) { should == 'edit_access_group_ssim'}
    its(:edit_person_field) { should == 'edit_access_person_ssim'}
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
      @asset = FactoryGirl.create(:group_edit_asset)
    end
    context "Then a collaborator with edit access (user permision)" do
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
    context "Then a collaborator with edit access (group permision)" do
      before do
        @user = FactoryGirl.build(:martia_morocco)
        RoleMapper.stub(:roles).with(@user).and_return(@user.roles)
      end
      subject { Ability.new(@user) }

      it "should be able to view the asset" do
        subject.can?(:read, @asset).should be_true
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
        RoleMapper.stub(:roles).with(@user).and_return(@user.roles)
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

  describe "custom method" do
    before do
      class MyAbility
        include Hydra::Ability
        self.ability_logic +=[:setup_my_permissions]

        def setup_my_permissions
          can :accept, ActiveFedora::Base
        end
      end
    end

    after do
      Object.send(:remove_const, :MyAbility)
    end

    subject { MyAbility.new(FactoryGirl.create(:staff)) }

    it "should be set the custom permission" do
      subject.can?(:accept, ActiveFedora::Base).should be_true
    end

  end

  describe "calling ability on two separate objects" do
    before do
      @asset1 = FactoryGirl.create(:org_read_access_asset)
      @asset2 = FactoryGirl.create(:asset)
      @user = FactoryGirl.build(:calvin_collaborator) # has access to @asset1, but not @asset2
    end
    subject { Ability.new(@user) }
    it "should be readable in the first instance and not in the second instance" do
      # We had a bug around this where it keeps returning the access for the first object queried
      subject.can?(:edit, @asset1).should be_true  
      subject.can?(:edit, @asset2).should be_false  
    end
  end

end
