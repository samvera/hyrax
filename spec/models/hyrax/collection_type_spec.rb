RSpec.describe Hyrax::CollectionType, type: :model do
  let(:collection_type) { create(:user_collection_type) }

  it "has basic metadata" do
    expect(collection_type).to respond_to(:title)
    expect(collection_type.title).not_to be_empty
    expect(collection_type).to respond_to(:description)
    expect(collection_type.description).not_to be_empty
    expect(collection_type).to respond_to(:machine_id)
    expect(collection_type.machine_id).not_to be_empty
  end

  it "has configuration properties with defaults" do
    expect(collection_type.nestable?).to be_truthy
    expect(collection_type.discoverable?).to be_truthy
    expect(collection_type.sharable?).to be_truthy
    expect(collection_type.allow_multiple_membership?).to be_truthy
    expect(collection_type.require_membership?).to be_falsey
    expect(collection_type.assigns_workflow?).to be_falsey
    expect(collection_type.assigns_visibility?).to be_falsey
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
      expect(described_class.exists?(machine_id: described_class::DEFAULT_ID)).to be_truthy
    end
  end

  describe "validations" do
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
    it 'returns instance of collection type when one with the gid exists' do
      machine_id = collection_type.machine_id
      requested_collection_type = Hyrax::CollectionType.find_by_gid('gid://internal/hyrax-collectiontype/1')
      expect(requested_collection_type.machine_id).to eq machine_id
    end

    it 'returns false if collection type with gid does NOT exist' do
      requested_collection_type = Hyrax::CollectionType.find_by_gid('gid://internal/hyrax-collectiontype/NO_EXIST')
      expect(requested_collection_type).to be_falsey
    end
  end

  describe '.find_by_gid!' do
    it 'returns instance of collection type when one with the gid exists' do
      machine_id = collection_type.machine_id
      requested_collection_type = Hyrax::CollectionType.find_by_gid!('gid://internal/hyrax-collectiontype/1')
      expect(requested_collection_type.machine_id).to eq machine_id
    end

    it 'raises error if collection type with gid does NOT exist' do
      gid = 'gid://internal/hyrax-collectiontype/NO_EXIST'
      expect { Hyrax::CollectionType.find_by_gid!(gid) }.to raise_error(ActiveRecord::RecordNotFound, "Couldn't find Hyrax::CollectionType matching GID '#{gid}'")
    end
  end
end
