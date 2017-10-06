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
      expect(ct).not_to be_discoverable
    end

    it "creates collection participants defined in options" do
      expect do
        described_class.create_collection_type
      end.to change(Hyrax::CollectionTypeParticipant, :count).by(described_class::DEFAULT_OPTIONS[:participants].count)
    end
  end

  describe '.add_default_participants' do
    let(:coltype) { create(:collection_type) }

    it 'adds the default participants to a collection type' do
      expect(Hyrax::CollectionTypeParticipant).to receive(:create!).exactly(2).times
      described_class.add_default_participants(coltype.id)
    end
  end

  describe '.add_participants' do
    let(:participants) { [{ agent_type: Hyrax::CollectionTypeParticipant::GROUP_TYPE, agent_id: 'test_group', access: Hyrax::CollectionTypeParticipant::MANAGE_ACCESS }] }
    let(:coltype) { create(:collection_type) }

    it 'adds the participants to a collection type' do
      expect(Hyrax::CollectionTypeParticipant).to receive(:create!)
      described_class.add_participants(coltype.id, participants)
    end
  end
end
