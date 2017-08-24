RSpec.describe Hyrax::CollectionType, clean_repo: true, type: :model do
  let(:collection_type) { build(:collection_type) }

  describe '.collection_type_settings_methods' do
    subject { described_class.collection_type_settings_methods }

    it { is_expected.to be_a(Array) }
  end

  describe '#collection_type_settings_methods' do
    subject { described_class.new.collection_type_settings_methods }

    it { is_expected.to be_a(Array) }
  end

  it "has basic metadata" do
    expect(collection_type).to respond_to(:title)
    expect(collection_type.title).not_to be_empty
    expect(collection_type).to respond_to(:description)
    expect(collection_type.description).not_to be_empty
    expect(collection_type).to respond_to(:machine_id)
  end

  it "has configuration properties with defaults" do
    expect(collection_type).to be_nestable
    expect(collection_type).to be_discoverable
    expect(collection_type).to be_sharable
    expect(collection_type).to allow_multiple_membership
    expect(collection_type).not_to require_membership
    expect(collection_type).not_to assign_workflow
    expect(collection_type).not_to assign_visibility
  end

  describe '#gid' do
    it 'returns the gid when id exists' do
      collection_type.id = 5
      expect(collection_type.gid.to_s).to eq 'gid://internal/hyrax-collectiontype/5'
    end

    it 'returns nil when id is nil' do
      collection_type.id = nil
      expect(collection_type.gid).to be_nil
    end
  end

  describe ".find_or_create_default_collection_type" do
    subject { described_class.find_or_create_default_collection_type }

    it 'creates a default collection type' do
      subject
      expect(described_class).to exist(machine_id: described_class::USER_COLLECTION_MACHINE_ID)
    end
  end

  describe "validations", :clean_repo do
    let(:collection_type) { create(:collection_type) }

    it "ensures the required fields have values" do
      collection_type.title = nil
      collection_type.machine_id = nil
      expect(collection_type).not_to be_valid
      expect(collection_type.errors.messages[:title]).not_to be_empty
      expect(collection_type.errors.messages[:machine_id]).not_to be_empty
    end
    it "ensures uniqueness" do
      is_expected.to validate_uniqueness_of(:title)
      is_expected.to validate_uniqueness_of(:machine_id)
    end
  end

  describe '.find_by_gid' do
    let(:collection_type) { create(:collection_type) }
    let(:nonexistent_gid) { 'gid://internal/hyrax-collectiontype/NO_EXIST' }

    it 'returns instance of collection type when one with the gid exists' do
      expect(Hyrax::CollectionType.find_by_gid(collection_type.gid)).to eq collection_type
    end

    it 'returns false if collection type with gid does NOT exist' do
      expect(Hyrax::CollectionType.find_by_gid(nonexistent_gid)).to eq false
    end
  end

  describe '.find_by_gid!' do
    let(:collection_type) { create(:collection_type) }
    let(:nonexistent_gid) { 'gid://internal/hyrax-collectiontype/NO_EXIST' }

    it 'returns instance of collection type when one with the gid exists' do
      expect(Hyrax::CollectionType.find_by_gid(collection_type.gid)).to eq collection_type
    end

    it 'raises error if collection type with gid does NOT exist' do
      expect { Hyrax::CollectionType.find_by_gid!(nonexistent_gid) }.to raise_error(ActiveRecord::RecordNotFound, "Couldn't find Hyrax::CollectionType matching GID '#{nonexistent_gid}'")
    end
  end

  describe "collections" do
    let!(:collection) { create(:collection, collection_type_gid: collection_type.gid.to_s) }
    let(:collection_type) { create(:collection_type) }

    it 'returns collections of this collection type' do
      expect(collection_type.collections.to_a).to include collection
    end

    it 'returns empty array if gid is nil' do
      expect(Collection.count).not_to be_zero
      expect(build(:collection_type).collections).to eq []
    end
  end

  describe "collections?" do
    let(:collection_type) { create(:collection_type) }

    it 'returns true if there are any collections of this collection type' do
      create(:collection, collection_type_gid: collection_type.gid.to_s)
      expect(collection_type).to have_collections
    end
    it 'returns false if there are not any collections of this collection type' do
      expect(collection_type).not_to have_collections
    end
  end

  describe "machine_id" do
    let(:collection_type) { described_class.new }

    it 'assigns machine_id on title=' do
      expect(collection_type.machine_id).to be_blank
      collection_type.title = "New Collection Type"
      expect(collection_type.machine_id).not_to be_blank
    end
  end

  describe "destroy" do
    before do
      allow(collection_type).to receive(:collections?).and_return(true)
    end

    it "fails if collections exist of this type" do
      expect(collection_type.destroy).to eq false
      expect(collection_type.errors).not_to be_empty
    end
  end

  describe "save" do
    before do
      allow(collection_type).to receive(:collections?).and_return(true)
    end

    it "fails if collections exist of this type" do
      expect(collection_type.save).to eq false
      expect(collection_type.errors).not_to be_empty
    end
  end
end
