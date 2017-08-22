RSpec.describe Hyrax::CollectionTypeParticipant, type: :model do
  let(:collection_type_participant) { create(:collection_type_participant) }

  it 'has basic metadata' do
    expect(collection_type_participant).to respond_to(:agent_id)
    expect(collection_type_participant.agent_id).not_to be_empty
    expect(collection_type_participant).to respond_to(:agent_type)
    expect(collection_type_participant.agent_type).not_to be_empty
    expect(collection_type_participant).to respond_to(:access)
    expect(collection_type_participant.access).not_to be_empty
  end
end
