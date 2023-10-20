# frozen_string_literal: true
RSpec.describe ::Collection, :active_fedora, type: :model do
  let(:collection) { build(:public_collection_lw) }

  it "has open visibility" do
    expect(collection.read_groups).to eq ['public']
  end

  describe "#validates_with" do
    before { collection.title = nil }
    it "ensures the collection has a title" do
      expect(collection).not_to be_valid
      expect(collection.errors.messages[:title]).to eq(["You must provide a title"])
    end
  end

  describe "#to_solr" do
    let(:user) { build(:user) }
    let(:collection) { build(:collection_lw, user: user, title: ['A good title']) }

    let(:solr_document) { collection.to_solr }

    it "has title information and depositor information" do
      expect(solr_document).to include 'title_tesim' => ['A good title'],
                                       'title_sim' => ['A good title'],
                                       'depositor_tesim' => [user.user_key],
                                       'depositor_ssim' => [user.user_key]
    end
  end

  describe "#depositor" do
    let(:user) { build(:user) }

    before do
      subject.apply_depositor_metadata(user)
    end

    it "has a depositor" do
      expect(subject.depositor).to eq(user.user_key)
    end
  end

  describe "#members_objects", clean_repo: true do
    let(:collection) { create(:collection_lw) }

    it "is empty by default" do
      expect(collection.member_objects).to match_array []
    end

    context "when adding members" do
      let(:work1) { valkyrie_create(:hyrax_work, title: 'Work 1') }
      let(:work2) { valkyrie_create(:hyrax_work, title: 'Work 2') }
      let(:work3) { valkyrie_create(:hyrax_work, title: 'Work 3') }

      it "allows multiple works to be added" do
        Hyrax::Collections::CollectionMemberService.add_members(collection_id: collection.id,
                                                                new_members: [work1, work2],
                                                                user: nil)
        expect(collection.reload.member_objects.map(&:id)).to match_array [work1.id.to_s, work2.id.to_s]
      end

      context 'when multiple membership checker returns a non-nil value' do
        before do
          allow(Hyrax::MultipleMembershipChecker).to receive(:new).with(item: work1).and_return(nil_checker)
          allow(Hyrax::MultipleMembershipChecker).to receive(:new).with(item: work2).and_return(checker)
          allow(Hyrax::MultipleMembershipChecker).to receive(:new).with(item: work3).and_return(nil_checker)
          allow(nil_checker).to receive(:check).and_return(nil)
          allow(checker).to receive(:check).and_return(error_message)
        end

        let(:checker) { double }
        let(:nil_checker) { double }
        let(:error_message) { 'Error: foo bar' }

        it 'fails to add the member' do
          begin
            Hyrax::Collections::CollectionMemberService.add_members(collection_id: collection.id,
                                                                    new_members: [work1, work2, work3],
                                                                    user: nil)
          rescue; end # rubocop:disable Lint/SuppressedException
          expect(collection.reload.member_objects.map(&:id)).to match_array [work1.id.to_s, work3.id.to_s]
        end
      end
    end
  end

  describe "#destroy", clean_repo: true do
    let(:collection) { create(:collection_lw) }
    let(:work1) { valkyrie_create(:hyrax_work) }

    before do
      Hyrax::Collections::CollectionMemberService.add_members(collection_id: collection.id,
                                                              new_members: [work1],
                                                              user: nil)
      collection.destroy
    end

    it "does not delete member works when deleted" do
      expect(Hyrax::Test::SimpleWorkLegacy.exists?(work1.id.to_s)).to be true
    end
  end

  describe "Collection by another name" do
    before do
      class OtherCollection < ActiveFedora::Base
        include Hyrax::CollectionBehavior
      end

      class Member < ActiveFedora::Base
        include Hydra::Works::WorkBehavior
      end

      Hyrax::Collections::CollectionMemberService.add_members(collection_id: collection.id,
                                                              new_members: [member.valkyrie_resource],
                                                              user: nil)
    end
    after do
      Object.send(:remove_const, :OtherCollection)
      Object.send(:remove_const, :Member)
    end

    let(:member) { Member.create }
    let(:collection) { OtherCollection.create(title: ['test title'], collection_type: FactoryBot.create(:user_collection_type)) }

    it "have members that know about the collection", clean_repo: true do
      member.reload
      expect(member.member_of_collections).to eq [collection]
    end
  end

  describe '#collection_type_gid', :clean_repo do
    subject(:collection) { described_class.new(collection_type_gid: collection_type.to_global_id) }

    let(:collection_type) { FactoryBot.create(:collection_type) }

    it 'has a collection_type_gid' do
      expect(collection.collection_type_gid).to eq collection_type.to_global_id.to_s
    end
  end

  describe '#collection_type_gid=' do
    let(:collection) { build(:collection_lw) }
    let(:collection_type) { create(:collection_type) }

    it 'sets gid' do
      collection.collection_type_gid = collection_type.to_global_id
      expect(collection.collection_type_gid).to eq collection_type.to_global_id.to_s
    end

    it 'throws ActiveRecord::RecordNotFound if cannot find collection type for the gid' do
      gid = 'gid://internal/Hyrax::CollectionType/999'
      expect { collection.collection_type_gid = gid }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'throws ActiveRecord::RecordNotFound if set to nil' do
      expect { collection.collection_type_gid = nil }.to raise_error(URI::InvalidURIError)
    end

    it 'updates the collection_type' do
      expect { collection.collection_type_gid = collection_type.to_global_id }
        .to change { Hyrax::CollectionType.for(collection: collection) }
        .from(create(:user_collection_type)).to(collection_type)
    end

    it 'throws ArgumentError if collection has already been persisted with a collection type' do
      collection.save!
      expect(collection.collection_type_gid).not_to be_nil
      expect { collection.collection_type_gid = FactoryBot.create(:collection_type).to_global_id }
        .to raise_error(RuntimeError, "Can't modify collection type of this collection")
    end
  end

  describe '.after_destroy' do
    it 'will destroy the associated permission template' do
      collection = build(:collection_lw, with_permission_template: true)
      expect { collection.destroy }.to change { Hyrax::PermissionTemplate.count }.by(-1)
    end
  end

  describe 'permission_template reset_access_controls_for' do
    let!(:user) { build(:user) }
    let(:collection_type) { create(:collection_type) }
    let!(:collection) { FactoryBot.build(:collection_lw, user: user, collection_type: collection_type) }
    let!(:permission_template) { build(:permission_template) }

    before do
      allow(collection).to receive(:permission_template).and_return(permission_template)
      allow(permission_template).to receive(:agent_ids_for).with(access: 'manage', agent_type: 'user').and_return(['mgr1@ex.com', 'mgr2@ex.com', user.user_key])
      allow(permission_template).to receive(:agent_ids_for).with(access: 'manage', agent_type: 'group').and_return(['managers', ::Ability.admin_group_name])
      allow(permission_template).to receive(:agent_ids_for).with(access: 'deposit', agent_type: 'user').and_return(['dep1@ex.com', 'dep2@ex.com'])
      allow(permission_template).to receive(:agent_ids_for).with(access: 'deposit', agent_type: 'group').and_return(['depositors', ::Ability.admin_group_name])
      allow(permission_template).to receive(:agent_ids_for).with(access: 'view', agent_type: 'user').and_return(['vw1@ex.com', 'vw2@ex.com'])
      allow(permission_template).to receive(:agent_ids_for).with(access: 'view', agent_type: 'group').and_return(['viewers', ::Ability.admin_group_name])
    end

    it 'resets user edit access' do
      expect(collection.edit_users).to match_array([user.user_key])
      permission_template.reset_access_controls_for(collection: collection)
      expect(collection.edit_users).to match_array([user.user_key, 'mgr1@ex.com', 'mgr2@ex.com'])
    end

    it 'resets group edit access' do
      expect(collection.edit_groups).to match_array([])
      permission_template.reset_access_controls_for(collection: collection)
      expect(collection.edit_groups).to match_array(['managers', ::Ability.admin_group_name])
    end

    it 'resets user read access' do
      expect(collection.read_users).to match_array([])
      permission_template.reset_access_controls_for(collection: collection)
      expect(collection.read_users).to match_array(['vw1@ex.com', 'vw2@ex.com', 'dep1@ex.com', 'dep2@ex.com'])
    end

    it 'resets group read access' do
      expect(collection.read_groups).to match_array([])
      permission_template.reset_access_controls_for(collection: collection)
      expect(collection.read_groups).to match_array(['viewers', 'depositors', ::Ability.admin_group_name])
    end
  end

  context 'collection factory' do
    let(:user) { build(:user) }

    describe 'permission template' do
      it 'will be created when with_permission_template is true' do
        expect { build(:collection_lw, with_permission_template: true) }.to change { Hyrax::PermissionTemplate.count }.by(1)
      end

      it 'will be created when with_permission_template is set to attributes identifying access' do
        expect { build(:collection_lw, with_permission_template: { manage_users: [user] }) }.to change { Hyrax::PermissionTemplate.count }.by(1)
        expect { build(:collection_lw, with_permission_template: { manage_users: [user], deposit_users: [user] }) }.to change { Hyrax::PermissionTemplate.count }.by(1)
      end

      it 'will be created when create_access is true' do
        expect { create(:collection_lw, with_permission_template: true) }.to change { Hyrax::PermissionTemplate.count }.by(1)
      end

      it 'will not be created by default' do
        expect { build(:collection_lw) }.not_to change { Hyrax::PermissionTemplate.count }
      end
    end

    describe 'permission template access' do
      it 'will not be created when with_permission_template is true' do
        expect { create(:collection, with_permission_template: true) }.not_to change { Hyrax::PermissionTemplateAccess.count }
      end

      it 'will be created when with_permission_template is set to attributes identifying access' do
        expect { create(:collection, with_permission_template: { manage_users: [user] }) }.to change { Hyrax::PermissionTemplateAccess.count }.by(1)
        expect { create(:collection, with_permission_template: { manage_users: [user], deposit_users: [user] }) }.to change { Hyrax::PermissionTemplateAccess.count }.by(2)
      end

      it 'will be created when create_access is true' do
        expect { build(:collection_lw, user: user, with_permission_template: true) }.to change { Hyrax::PermissionTemplate.count }.by(1)
      end

      it 'will not be created by default' do
        expect { build(:collection_lw) }.not_to change { Hyrax::PermissionTemplateAccess.count }
      end
    end
  end
end
