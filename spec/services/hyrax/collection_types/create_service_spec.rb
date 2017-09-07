RSpec.describe Hyrax::CollectionTypes::CreateService do
  describe ".create_collection_type" do
    it 'creates a default collection type when no options are received' do
      described_class.create_collection_type
      expect(Hyrax::CollectionType).to exist(machine_id: Hyrax::CollectionType::USER_COLLECTION_MACHINE_ID)
    end

    it 'creates a collection type for the options received' do
      options = {
        description: 'A collection type with options.',
        discoverable: false
      }
      described_class.create_collection_type(machine_id: 'custom_type', title: 'Custom Type', options: options)
      ct = Hyrax::CollectionType.find_by_machine_id('custom_type')
      expect(ct.description).to include('with options')
      expect(ct.discoverable?).to be_falsey
    end
  end
end
