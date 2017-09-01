RSpec.describe Collection, type: :model do
  let(:collection) { build(:public_collection) }

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
    let(:user) { create(:user) }
    let(:collection) { build(:collection, user: user, title: ['A good title']) }

    let(:solr_document) { collection.to_solr }

    it "has title information" do
      expect(solr_document).to include 'title_tesim' => ['A good title'],
                                       'title_sim' => ['A good title']
    end

    it "has depositor information" do
      expect(solr_document).to include 'depositor_tesim' => [user.user_key],
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

  describe "#members_objects" do
    let(:collection) { create(:collection) }

    it "is empty by default" do
      expect(collection.member_objects).to match_array []
    end

    context "when adding members" do
      let(:work1) { create(:work) }
      let(:work2) { create(:work) }
      let(:work3) { create(:work) }

      it "allows multiple files to be added" do
        collection.add_member_objects [work1.id, work2.id, work3.id]
        collection.save!
        expect(collection.reload.member_objects).to match_array [work1, work2, work3]
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
          collection.add_member_objects [work1.id, work2.id, work3.id]
          collection.save!
          expect(collection.reload.member_objects).to match_array [work1, work3]
        end
      end
    end
  end

  it "has a title" do
    subject.title = ["title"]
    subject.save!
    expect(subject.reload.title).to eq ["title"]
  end

  it "has a description" do
    subject.title = ["title"]
    subject.description = ["description"]
    subject.save!
    expect(subject.reload.description).to eq ["description"]
  end

  describe "#destroy" do
    let(:collection) { build(:collection) }
    let(:work1) { create(:work) }
    let(:work2) { create(:work) }

    before do
      collection.add_member_objects [work1.id, work2.id]
      collection.save!
      collection.destroy
    end

    it "does not delete member files when deleted" do
      expect(GenericWork.exists?(work1.id)).to be true
      expect(GenericWork.exists?(work2.id)).to be true
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
      collection.add_member_objects member.id
    end
    after do
      Object.send(:remove_const, :OtherCollection)
      Object.send(:remove_const, :Member)
    end

    let(:member) { Member.create }
    let(:collection) { OtherCollection.create(title: ['test title']) }

    it "have members that know about the collection" do
      member.reload
      expect(member.member_of_collections).to eq [collection]
    end
  end

  describe 'after_initialize' do
    let(:collection_type) { create(:collection_type) }

    it 'sets collection_type_gid to default collection type if not already set' do
      expect(described_class.new.collection_type_gid).to eq Hyrax::CollectionType.find_or_create_default_collection_type.gid
    end

    it 'does not set collection_type_gid if passed in to initializer' do
      expect(described_class.new(collection_type_gid: collection_type.gid).collection_type_gid).to eq collection_type.gid
    end

    it 'does not override preexisting collection_type_gid' do
      collection = create(:collection, collection_type_gid: collection_type.gid)
      expect(described_class.find(collection.id).collection_type_gid).to eq collection_type.gid
    end
  end

  describe '#collection_type_gid', :clean_repo do
    subject(:collection) { described_class.new(collection_type_gid: collection_type.gid) }

    let(:collection_type) { create(:collection_type) }

    it 'has a collection_type_gid' do
      expect(collection.collection_type_gid).to eq collection_type.gid
    end
  end

  describe '#collection_type_gid=' do
    let(:collection) { build(:collection) }
    let(:collection_type) { create(:collection_type) }

    it 'sets gid' do
      collection.collection_type_gid = collection_type.gid
      expect(collection.collection_type_gid).to eq collection_type.gid
    end

    it 'throws ActiveRecord::RecordNotFound if cannot find collection type for the gid' do
      gid = 'gid://internal/hyrax-collectiontype/999'
      expect { collection.collection_type_gid = gid }.to raise_error(ActiveRecord::RecordNotFound, "Couldn't find Hyrax::CollectionType matching GID '#{gid}'")
    end

    it 'throws ActiveRecord::RecordNotFound if set to nil' do
      expect { collection.collection_type_gid = nil }.to raise_error(ActiveRecord::RecordNotFound, "Couldn't find Hyrax::CollectionType matching GID ''")
    end

    it 'updates the collection_type instance variable' do
      expect { collection.collection_type_gid = collection_type.gid }.to change { collection.collection_type }.from(Hyrax::CollectionType.find_or_create_default_collection_type).to(collection_type)
    end

    it 'throws ArgumentError if collection has already been persisted with a collection type' do
      collection.save!
      expect(collection.collection_type_gid).not_to be_nil
      expect { collection.collection_type_gid = create(:collection_type).gid }.to raise_error(RuntimeError, "Can't modify collection type of this collection")
    end
  end

  describe '#collection_type' do
    let(:collection) { described_class.new(collection_type: collection_type) }
    let(:collection_type) { create(:collection_type) }

    it 'returns a collection_type instance from the collection_type_gid' do
      expect(collection.collection_type).to be_kind_of(Hyrax::CollectionType)
      expect(collection.collection_type).to eq collection_type
      expect(collection.collection_type.gid).to eq collection_type.gid
    end
  end

  describe 'collection type delegated methods' do
    subject { build(:collection) }

    it { is_expected.to delegate_method(:nestable?).to(:collection_type) }
    it { is_expected.to delegate_method(:discoverable?).to(:collection_type) }
    it { is_expected.to delegate_method(:sharable?).to(:collection_type) }
    it { is_expected.to delegate_method(:allow_multiple_membership?).to(:collection_type) }
    it { is_expected.to delegate_method(:require_membership?).to(:collection_type) }
    it { is_expected.to delegate_method(:assigns_workflow?).to(:collection_type) }
    it { is_expected.to delegate_method(:assigns_visibility?).to(:collection_type) }
  end
end
