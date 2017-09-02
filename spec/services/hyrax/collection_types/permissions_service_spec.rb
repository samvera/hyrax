RSpec.describe Hyrax::CollectionTypes::PermissionsService do
  let(:user_collection_type) { create(:user_collection_type) }
  let(:user) { create(:user) }

  # TODO: stubbed method returns all collection types. complete spec when corresponding method stub is complete.
  describe "#can_create_collection_types" do
    let(:subject) { described_class.can_create_collection_types(user: user) }

    it 'returns types of collections user is authorized to create' do
      expect(subject).to eq(Hyrax::CollectionType.all)
    end
  end
end
