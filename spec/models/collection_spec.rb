RSpec.describe Collection do
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

    context "adding members" do
      let(:work1) { create(:work) }
      let(:work2) { create(:work) }
      let(:work3) { create(:work) }

      it "allows multiple files to be added" do
        collection.add_member_objects [work1.id, work2.id, work3.id]
        collection.save!
        expect(collection.reload.member_objects).to match_array [work1, work2, work3]
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

  describe '#collection_type_gid' do
    it 'has a collection_type_gid' do
      subject.title = ['title']
      subject.collection_type_gid = 'gid://internal/hyrax-collectiontype/5'
      subject.save!
      expect(subject.reload.collection_type_gid).to eq 'gid://internal/hyrax-collectiontype/5'
    end
  end

  describe '#load_collection_type_instance' do
    context 'when gid exists in collection object' do
      let(:collection) { described_class.new(title: ['title']) }
      let(:collection_type) { Hyrax::CollectionType.new(id: 5) }

      before do
        allow(Hyrax::CollectionType).to receive(:find_by_gid!).with('gid://internal/hyrax-collectiontype/5').and_return(collection_type)
        allow(collection_type).to receive(:persisted?).and_return(true)
      end

      it 'loads instance of collection type based on gid' do
        collection.collection_type_gid = 'gid://internal/hyrax-collectiontype/5'
        collection.save!
        col = described_class.find(collection.id)
        expect(col.collection_type).to be_a Hyrax::CollectionType
        expect(col.collection_type.id).to eq 5
      end
    end

    context 'when gid in collection object is nil' do
      let(:collection) { create(:collection, title: ['title']) }

      subject { described_class.find(collection.id) }

      it 'loads default collection type' do
        expect(subject.collection_type).to be_a Hyrax::CollectionType
        expect(subject.collection_type.machine_id).to eq Hyrax::CollectionType::USER_COLLECTION_MACHINE_ID
      end
    end
  end

  describe '#collection_type_gid=' do
    let(:collection) { described_class.new }

    it 'sets gid' do
      gid = 'gid://internal/hyrax-collectiontype/10'
      collection.collection_type_gid = gid
      expect(collection.collection_type_gid).to eq gid
    end
  end

  describe '#collection_type' do
    let(:collection) { described_class.new }

    it 'returns nil if gid is nil' do
      collection.collection_type_gid = nil
      expect(collection.collection_type).to be_nil
    end

    it 'returns collection_type if already set' do
      gid89 = 'gid://internal/hyrax-collectiontype/89'
      allow(Hyrax::CollectionType).to receive(:find_by_gid!).with(gid89).and_return(Hyrax::CollectionType.new(id: 89))
      collection.collection_type_gid = gid89
      expect(collection.collection_type).to be_kind_of(Hyrax::CollectionType)
      expect(collection.collection_type.gid).to eq gid89
    end

    it 'will not change value' do
      gid89 = 'gid://internal/hyrax-collectiontype/89'
      gid99 = 'gid://internal/hyrax-collectiontype/99'
      allow(Hyrax::CollectionType).to receive(:find_by_gid!).with(gid89).and_return(Hyrax::CollectionType.new(id: 89))
      collection.collection_type_gid = gid89
      collection.collection_type
      collection.collection_type_gid = gid99
      expect(collection.collection_type).to be_kind_of(Hyrax::CollectionType)
      expect(collection.collection_type.gid).to eq gid89
    end

    it 'throws ActiveRecord::RecordNotFound if cannot find collection type for the gid' do
      gid = 'gid://internal/hyrax-collectiontype/999'
      collection.collection_type_gid = gid
      # TODO: Should we capture the ActiveRecord error and produce something nicer?
      expect { collection.collection_type }.to raise_error(ActiveRecord::RecordNotFound, "Couldn't find Hyrax::CollectionType matching GID '#{gid}'")
    end
  end

  describe 'type properties' do
    subject { collection }

    let(:collection_type) { build(:collection_type) }

    before do
      allow(collection).to receive(:collection_type).and_return(collection_type)
    end

    describe '#nestable' do
      before { collection_type.nestable = property_value }
      context 'when false' do
        let(:property_value) { false }

        it { is_expected.not_to be_nestable }
      end

      context 'when true' do
        let(:property_value) { true }

        it { is_expected.to be_nestable }
      end
    end

    describe '#discoverable' do
      before { collection_type.discoverable = property_value }

      context 'when false' do
        let(:property_value) { false }

        it { is_expected.not_to be_discoverable }
      end

      context 'when true' do
        let(:property_value) { true }

        it { is_expected.to be_discoverable }
      end
    end

    describe '#sharable' do
      before { collection_type.sharable = property_value }

      context 'when false' do
        let(:property_value) { false }

        it { is_expected.not_to be_sharable }
      end

      context 'when true' do
        let(:property_value) { true }

        it { is_expected.to be_sharable }
      end
    end

    describe '#allow_multiple_membership' do
      before { collection_type.allow_multiple_membership = property_value }

      context 'when false' do
        let(:property_value) { false }

        it { is_expected.not_to allow_multiple_membership }
      end

      context 'when true' do
        let(:property_value) { true }

        it { is_expected.to allow_multiple_membership }
      end
    end

    describe '#require_membership' do
      before { collection_type.require_membership = property_value }

      context 'when false' do
        let(:property_value) { false }

        it { is_expected.not_to require_membership }
      end

      context 'when true' do
        let(:property_value) { true }

        it { is_expected.to require_membership }
      end
    end

    describe '#assigns_workflow' do
      before { collection_type.assigns_workflow = property_value }

      context 'when false' do
        let(:property_value) { false }

        it { is_expected.not_to assign_workflow }
      end

      context 'when true' do
        let(:property_value) { true }

        it { is_expected.to assign_workflow }
      end
    end

    describe '#assigns_visibility' do
      before { collection_type.assigns_visibility = property_value }

      context 'when false' do
        let(:property_value) { false }

        it { is_expected.not_to assign_visibility }
      end

      context 'when true' do
        let(:property_value) { true }

        it { is_expected.to assign_visibility }
      end
    end
  end
end
