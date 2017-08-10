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
    it 'returns the gid when id is not nil' do
      collection_type.id = 5
      expect(collection_type.gid.to_s).to eq 'gid://internal/hyrax-collectiontype/5'
    end

    it 'returns the gid when id is nil' do
      collection_type.id = nil
      expect(collection_type.gid).to be_nil
    end
  end
end
