require 'spec_helper'

describe Hydra::AdminPolicy do
  before do
    allow(Devise).to receive(:authentication_keys).and_return(['uid'])
  end

  describe "when setting attributes" do
    before do
      subject.title = ["My title"]
      subject.description = ["My description"]
    end
    its(:title) { is_expected.to eq "My title"}
    its(:description) { is_expected.to eq "My description"}
  end


  describe "to_solr" do
    subject { Hydra::AdminPolicy.new(:title=>["Foobar"]).to_solr }
    it "should have title_ssim" do
      expect(subject[ActiveFedora.index_field_mapper.solr_name('title', type: :string)]).to eq ["Foobar"]
    end
  end

  describe "updating default permissions" do
    it "should create new group permissions" do
      subject.default_permissions.build({:name=>'group1', :access=>'discover', :type=>'group'})
      expect(subject.default_permissions.map(&:to_hash)).to eq [{:type=>'group', :access=>'discover', :name=>'group1'}]
    end
    it "should create new user permissions" do
      subject.default_permissions.build({:name=>'user1', :access=>'discover', :type=>'person'})
      expect(subject.default_permissions.map(&:to_hash)).to eq [{:type=>'person', :access=>'discover', :name=>'user1'}]
    end
    it "should not replace existing groups" do
      subject.default_permissions.build({:name=>'group1', :access=>'discover', :type=>'group'})
      subject.default_permissions.build({:name=>'group2', :access=>'discover', :type=>'group'})
      expect(subject.default_permissions.map(&:to_hash)).to eq [{:type=>'group', :access=>'discover', :name=>'group1'},
                                   {:type=>'group', :access=>'discover', :name=>'group2'}]
    end
    it "should not replace existing users" do
      subject.default_permissions.build({:name=>'user1', :access=>'discover', :type=>'person'})
      subject.default_permissions.build({:name=>'user2', :access=>'discover', :type=>'person'})
      expect(subject.default_permissions.map(&:to_hash)).to eq [{:type=>'person', :access=>'discover', :name=>'user1'},
                                   {:type=>'person', :access=>'discover', :name=>'user2'}]
    end
    it "should update permissions on existing users" do
      subject.default_permissions.build({:name=>'user1', :access=>'discover', :type=>'person'})
      subject.default_permissions.first.mode = Hydra::AccessControls::Mode.new(::ACL.Write)
      expect(subject.default_permissions.map(&:to_hash)).to eq [{:type=>'person', :access=>'edit', :name=>'user1'}]
    end
    it "should update permissions on existing groups" do
      subject.default_permissions.build({:name=>'group1', :access=>'discover', :type=>'group'})
      subject.default_permissions.first.mode = Hydra::AccessControls::Mode.new(::ACL.Write)
      expect(subject.default_permissions.map(&:to_hash)).to eq [{:type=>'group', :access=>'edit', :name=>'group1'}]
    end
    it "should assign user permissions when :type == 'person'" do
      subject.default_permissions.build({:name=>'user1', :access=>'discover', :type=>'person'})
      expect(subject.default_permissions.map(&:to_hash)).to eq [{:type=>'person', :access=>'discover', :name=>'user1'}]
    end
    it "should raise an ArgumentError when the :type hashkey is invalid" do
      expect { subject.default_permissions.build({:name=>'user1', :access=>'read', :type=>'foo'}) }.to raise_error(ArgumentError, 'Unknown agent type "foo"')
    end
  end

  describe "Inheritable rights" do
    let(:policy) { described_class.new }
    before do
      policy.default_permissions.build([
        {:name=>"africana-faculty", :access=>"edit", :type=>"group"},
        {:name=>"cool-kids", :access=>"edit", :type=>"group"},
        {:name=>"julius_caesar", :access=>"edit", :type=>"person"},
        {:name=>"slightlycoolkids", :access=>"read", :type=>"group"},
        {:name=>"nero", :access=>"read", :type=>"person"},
        {:name=>"posers", :access=>"discover", :type=>"group"},
        {:name=>"constantine", :access=>"discover", :type=>"person"}
      ])
      policy.build_default_embargo.embargo_release_date = "2102-10-01"
    end

    describe "persisting" do
      before do
        policy.save!
        policy.reload
      end

      it "has the permissions that were set" do
        expect(policy.default_permissions.size).to eq 7
      end

    end

    describe "indexing" do
      subject { policy.to_solr }

      it "should not affect normal solr permissions fields" do
        expect(subject).to_not have_key Hydra.config.permissions.discover.group
        expect(subject).to_not have_key Hydra.config.permissions.discover.individual
        expect(subject).to_not have_key Hydra.config.permissions.read.group
        expect(subject).to_not have_key Hydra.config.permissions.read.individual
        expect(subject).to_not have_key Hydra.config.permissions.edit.group
        expect(subject).to_not have_key Hydra.config.permissions.edit.individual
        expect(subject).to_not have_key Hydra.config.permissions.embargo.release_date
      end

      it "should provide prefixed/inherited solr permissions fields" do
        expect(subject[Hydra.config.permissions.inheritable.discover.group]).to eq ["posers"]
        expect(subject[Hydra.config.permissions.inheritable.discover.individual]).to eq ["constantine"]
        expect(subject[Hydra.config.permissions.inheritable.read.group]).to eq ["slightlycoolkids"]
        expect(subject[Hydra.config.permissions.inheritable.read.individual]).to eq ["nero"]
        expect(subject[Hydra.config.permissions.inheritable.edit.group]).to match_array ["africana-faculty", "cool-kids"]

        expect(subject[Hydra.config.permissions.inheritable.edit.individual]).to eq ["julius_caesar"]
        expect(subject[Hydra.config.permissions.inheritable.embargo.release_date]).to eq DateTime.parse("2102-10-01").to_time.utc.iso8601
      end
    end

  end

  #
  # Policy-based Access Controls
  #
  describe "When accessing assets with Policies associated" do
    let(:user) { FactoryGirl.build(:martia_morocco) }

    before do
      allow(user).to receive(:groups).and_return(["faculty", "africana-faculty"])
    end

    before(:all) do
      class TestAbility
        include Hydra::PolicyAwareAbility
      end
    end

    after(:all) do
      Object.send(:remove_const, :TestAbility)
    end

    subject { TestAbility.new(user) }

    context "Given a policy grants read access to a group I belong to" do
      before do
        @policy = Hydra::AdminPolicy.new
        @policy.default_permissions.build({:type=>"group", :access=>"read", :name=>"africana-faculty"})
        @policy.save
      end

    	context "And a subscribing asset does not grant access" do
    	  before do
          @asset = ModsAsset.new()
          @asset.admin_policy = @policy
          @asset.save
        end

    		it "Then I should be able to view the asset" do
    		  expect(subject.can?(:read, @asset)).to be true
  		  end

        it "Then I should not be able to edit, update and destroy the asset" do
          expect(subject.can?(:edit, @asset)).to be false
          expect(subject.can?(:update, @asset)).to be false
          expect(subject.can?(:destroy, @asset)).to be false
        end
      end
    end

    context "Given a policy grants edit access to a group I belong to" do
      before do
        @policy = Hydra::AdminPolicy.new
        @policy.default_permissions.build({:type=>"group", :access=>"edit", :name=>"africana-faculty"})
        @policy.save
      end

    	context "And a subscribing asset does not grant access" do
    	  before do
          @asset = ModsAsset.new()
          @asset.admin_policy = @policy
          @asset.save
        end

    		it "Then I should be able to view the asset" do
    		  expect(subject.can?(:read, @asset)).to be true
  		  end

    		it "Then I should be able to edit/update/destroy the asset" do
          expect(subject.can?(:edit, @asset)).to be true
          expect(subject.can?(:update, @asset)).to be true
          expect(subject.can?(:destroy, @asset)).to be true
        end
  		end

    	context "And a subscribing asset grants read access to me as an individual" do
    	  before do
          @asset = ModsAsset.new()
          @asset.read_users = [user.uid]
          @asset.admin_policy = @policy
          @asset.save
        end

    		it "Then I should be able to view the asset" do
    		  expect(subject.can?(:read, @asset)).to be true
  		  end

        it "Then I should be able to edit/update/destroy the asset" do
          expect(subject.can?(:edit, @asset)).to be true
          expect(subject.can?(:update, @asset)).to be true
          expect(subject.can?(:destroy, @asset)).to be true
        end
      end
    end

    context "Given a policy does not grant access to any group I belong to" do
      before do
        @policy = Hydra::AdminPolicy.new
        @policy.save
      end

      context "And a subscribing asset does not grant access" do
        before do
          @asset = ModsAsset.new()
          @asset.admin_policy = @policy
          @asset.save
        end

  		  it "Then I should not be able to view the asset" do
    		  expect(subject.can?(:read, @asset)).to be false
  		  end

        it "Then I should not be able to edit/update/destroy the asset" do
          expect(subject.can?(:edit, @asset)).to be false
          expect(subject.can?(:update, @asset)).to be false
          expect(subject.can?(:destroy, @asset)).to be false
        end
      end

      context "And a subscribing asset grants read access to me as an individual" do
        before do
          @asset = ModsAsset.new()
          @asset.read_users = [user.uid]
          @asset.admin_policy = @policy
          @asset.save
        end

  		  it "Then I should be able to view the asset" do
    		  expect(subject.can?(:read, @asset)).to be true
  		  end

        it "Then I should not be able to edit/update/destroy the asset" do
          expect(subject.can?(:edit, @asset)).to be false
          expect(subject.can?(:update, @asset)).to be false
          expect(subject.can?(:destroy, @asset)).to be false
        end
      end
    end
  end
end
