require 'spec_helper'
require 'cancan/matchers'

describe Ability do
  describe "class methods" do
    subject { Ability }
    its(:read_group_field) { should == 'read_access_group_ssim'}
    its(:read_user_field) { should == 'read_access_person_ssim'}
    its(:edit_group_field) { should == 'edit_access_group_ssim'}
    its(:edit_user_field) { should == 'edit_access_person_ssim'}
    its(:discover_group_field) { should == 'discover_access_group_ssim'}
    its(:discover_user_field) { should == 'discover_access_person_ssim'}
  end

  context "for a not-signed in user" do
    before do
      allow_any_instance_of(User).to receive(:email).and_return(nil)
      allow_any_instance_of(User).to receive(:new_record?).and_return(true)
    end
    subject { Ability.new(nil) }
    it "should call custom_permissions" do
      expect_any_instance_of(Ability).to receive(:custom_permissions)
      subject.can?(:delete, 7)
    end
    it { should_not be_able_to(:create, ActiveFedora::Base) }
  end

  context "for a signed in user" do
    before do
      @user = FactoryGirl.build(:registered_user)
    end
    subject { Ability.new(@user) }

    it { should_not be_able_to(:create, ActiveFedora::Base) }
  end


# NOTES:
#   See spec/requests/... for test coverage describing WHAT should appear on a page based on access permissions
#   Test coverage for discover permission is in spec/requests/gated_discovery_spec.rb

  describe "Given an asset that has been made publicly discoverable" do
    let(:asset) { FactoryGirl.create(:asset) }
    before do
      asset.permissions_attributes = [{ name: "public", access: "discover", type: "group" }, { name: "joe_creator", access: "edit", type: "person" }, { name: "calvin_collaborator", access: "edit", type: "person" }]
      asset.save
    end

    context "Then a not-signed-in user" do
      subject { Ability.new(nil) }
      it { should     be_able_to(:discover, asset) }
      it { should_not be_able_to(:read, asset) }
      it { should_not be_able_to(:edit, asset) }
      it { should_not be_able_to(:update, asset) }
      it { should_not be_able_to(:destroy, asset) }
    end

    context "Then a registered user" do
      before do
        @user = FactoryGirl.build(:registered_user)
      end
      subject { Ability.new(@user) }
      it { should     be_able_to(:discover, asset) }
      it { should_not be_able_to(:read, asset) }
      it { should_not be_able_to(:edit, asset) }
      it { should_not be_able_to(:update, asset) }
      it { should_not be_able_to(:destroy, asset) }
    end
  end

  describe "Given an asset that has been made publicly available (ie. open access)" do
    #let(:asset) { FactoryGirl.create(:open_access_asset) }
    let(:asset) { FactoryGirl.create(:asset) }
    before do
      asset.permissions_attributes = [{ name: "public", access: "read", type: "group" }, { name: "joe_creator", access: "edit", type: "person" }, { name: "calvin_collaborator", access: "edit", type: "person" }]
      asset.save
    end

    context "Then a not-signed-in user" do
      subject { Ability.new(nil) }
      it { should     be_able_to(:discover, asset) }
      it { should     be_able_to(:read, asset) }
      it { should_not be_able_to(:edit, asset) }
      it { should_not be_able_to(:update, asset) }
      it { should_not be_able_to(:destroy, asset) }
    end

    context "Then a registered user" do
      before do
        @user = FactoryGirl.build(:registered_user)
      end
      subject { Ability.new(@user) }
      it { should     be_able_to(:discover, asset) }
      it { should     be_able_to(:read, asset) }
      it { should_not be_able_to(:edit, asset) }
      it { should_not be_able_to(:update, asset) }
      it { should_not be_able_to(:destroy, asset) }
    end
  end

  describe "Given an asset with no custom access set" do
    #let(:asset) { FactoryGirl.create(:default_access_asset) }
    let(:asset) { FactoryGirl.create(:asset) }
    before do
      asset.permissions_attributes = [{ name: "joe_creator", access: "edit", type: "person" }]
      asset.save
    end
    let(:solr_doc) { SolrDocument.new(asset.to_solr.merge(id: asset.id)) }
    context "Then a not-signed-in user" do
      let(:user) { User.new.tap {|u| u.new_record = true } }
      subject { Ability.new(user) }
      it { should_not be_able_to(:discover, asset) }
      it { should_not be_able_to(:read, asset) }
      it { should_not be_able_to(:edit, asset) }
      it { should_not be_able_to(:update, asset) }
      it { should_not be_able_to(:destroy, asset) }
    end
    context "Then a registered user" do
      subject { Ability.new(FactoryGirl.build(:registered_user)) }
      it { should_not be_able_to(:discover, asset) }
      it { should_not be_able_to(:read, asset) }
      it { should_not be_able_to(:edit, asset) }
      it { should_not be_able_to(:update, asset) }
      it { should_not be_able_to(:destroy, asset) }
    end
    context "Then the Creator" do
      subject { Ability.new(FactoryGirl.build(:joe_creator)) }
      it { should     be_able_to(:discover, asset) }
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
    # let(:asset) { FactoryGirl.create(:org_read_access_asset) }
    let(:asset) { FactoryGirl.create(:asset) }
    before do
      asset.permissions_attributes = [{ name: "registered", access: "read", type: "group" }, { name: "joe_creator", access: "edit", type: "person" }, { name: "calvin_collaborator", access: "edit", type: "person" }]
      asset.save
    end
    context "The a registered user" do
      before do
        @user = FactoryGirl.build(:registered_user)
      end
      subject { Ability.new(@user) }

      it { should     be_able_to(:discover, asset) }
      it { should     be_able_to(:read, asset) }
      it { should_not be_able_to(:edit, asset) }
      it { should_not be_able_to(:update, asset) }
      it { should_not be_able_to(:destroy, asset) }
      it { should_not be_able_to(:admin, asset) }
    end
  end

  describe "Given an asset with collaborator" do
    # let(:asset) { FactoryGirl.create(:group_edit_asset) }
    let(:asset) { FactoryGirl.create(:asset) }
    before do
      asset.permissions_attributes = [{ name:"africana-faculty", access: "edit", type: "group" }, {name: "calvin_collaborator", access: "edit", type: "person"}]
      asset.save
    end
    after { asset.destroy }
    context "Then a collaborator with edit access (user permision)" do
      before do
        @user = FactoryGirl.build(:calvin_collaborator)
      end
      subject { Ability.new(@user) }

      it { should     be_able_to(:discover, asset) }
      it { should     be_able_to(:read, asset) }
      it { should     be_able_to(:edit, asset) }
      it { should     be_able_to(:update, asset) }
      it { should     be_able_to(:destroy, asset) }
      it { should_not be_able_to(:admin, asset) }
    end

    context "Then a collaborator with edit access (group permision)" do
      before do
        @user = FactoryGirl.build(:martia_morocco)
        allow(RoleMapper).to receive(:roles).with(@user).and_return(@user.roles)
      end
      subject { Ability.new(@user) }

      it { should     be_able_to(:read, asset) }
    end
  end

  describe "Given an asset where dept can read & registered users can discover" do
    # let(:asset) { FactoryGirl.create(:dept_access_asset) }
    let(:asset) { FactoryGirl.create(:asset) }
    before do
      asset.permissions_attributes = [{ name: "africana-faculty", access: "read", type: "group" }, { name: "joe_creator", access: "edit", type: "person" }]
      asset.save
    end
    context "Then a registered user" do
      before do
        @user = FactoryGirl.build(:registered_user)
      end
      subject { Ability.new(@user) }

      it { should_not be_able_to(:discover, asset) }
      it { should_not be_able_to(:read, asset) }
      it { should_not be_able_to(:edit, asset) }
      it { should_not be_able_to(:update, asset) }
      it { should_not be_able_to(:destroy, asset) }
      it { should_not be_able_to(:admin, asset) }
    end

    context "Then someone whose role/group has read access" do
      before do
        @user = FactoryGirl.build(:martia_morocco)
        allow(RoleMapper).to receive(:roles).with(@user).and_return(@user.roles)
      end
      subject { Ability.new(@user) }

      it { should     be_able_to(:discover, asset) }
      it { should     be_able_to(:read, asset) }
      it { should_not be_able_to(:edit, asset) }
      it { should_not be_able_to(:update, asset) }
      it { should_not be_able_to(:destroy, asset) }
      it { should_not be_able_to(:admin, asset) }
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

    it { should be_able_to(:accept, ActiveFedora::Base) }

  end

  describe "calling ability on two separate objects" do
    #asset1 = FactoryGirl.create(:org_read_access_asset)
    let(:asset1) { FactoryGirl.create(:asset) }
    let(:asset2) { FactoryGirl.create(:asset) }
    before do
      asset1.permissions_attributes = [{ name: "registered", access: "read", type: "group" }, { name: "joe_creator", access: "edit", type: "person" }, { name: "calvin_collaborator", access: "edit", type: "person" }]
      asset1.save
      @user = FactoryGirl.build(:calvin_collaborator) # has access to @asset1, but not @asset2
    end
    after do
      asset1.destroy
      asset2.destroy
    end
    subject { Ability.new(@user) }
    it "should be readable in the first instance and not in the second instance" do
      # We had a bug around this where it keeps returning the access for the first object queried
      expect(subject).to be_able_to(:edit, asset1)
      expect(subject).to_not be_able_to(:edit, asset2)
    end
  end

  describe "download permissions" do
    subject { Ability.new(user) }
    let(:asset) { FactoryGirl.create(:asset) }
    let(:user) { FactoryGirl.build(:user) }
    let(:file) { ActiveFedora::File.new() }

    before { allow(file).to receive(:uri).and_return(uri) }
    after { asset.destroy }

    context "in AF < 9.2" do
      let(:uri) { "#{asset.uri}/ds1" }

      context "user has read permission on the object" do
        before do
          asset.read_users = [user.user_key]
          asset.save!
        end

        it { should be_able_to(:read, asset.id) }
        it { should be_able_to(:download, file) }
      end

      context "user lacks read permission on the object and file" do
        it { should_not be_able_to(:read, asset) }
        it { should_not be_able_to(:download, file) }
      end
    end

    context "in AF >= 9.2" do
      let(:uri) { RDF::URI("#{asset.uri}/ds1") }

      context "user has read permission on the object" do
        before do
          asset.read_users = [user.user_key]
          asset.save!
        end

        it { should be_able_to(:read, asset.id) }
        it { should be_able_to(:download, file) }
      end
    end
  end
end
