# frozen_string_literal: true
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

  describe "validations", :clean_repo do
    describe '#agent_id' do
      it { is_expected.to validate_presence_of(:agent_id) }
    end
    describe '#agent_type' do
      it { is_expected.to validate_presence_of(:agent_type) }
      it { is_expected.not_to allow_value('somethingelse').for(:agent_type) }
      it { is_expected.to allow_value(Hyrax::CollectionTypeParticipant::USER_TYPE).for(:agent_type) }
      it { is_expected.to allow_value(Hyrax::CollectionTypeParticipant::GROUP_TYPE).for(:agent_type) }
      it "showd error message for wrong agent_type" do
        collection_type_participant.agent_type = "BAD_TYPE"
        collection_type_participant.valid?
        expect(collection_type_participant.errors[:agent_type]).to include "BAD_TYPE is not a valid agent type.  Accepts: group, user"
      end
    end
    describe '#access' do
      it { is_expected.to validate_presence_of(:access) }
      it { is_expected.not_to allow_value('somethingelse').for(:access) }
      it { is_expected.to allow_value(Hyrax::CollectionTypeParticipant::MANAGE_ACCESS).for(:access) }
      it { is_expected.to allow_value(Hyrax::CollectionTypeParticipant::CREATE_ACCESS).for(:access) }
      it "showd error message for wrong access" do
        collection_type_participant.access = "BAD_ACCESS"
        collection_type_participant.valid?
        expect(collection_type_participant.errors[:access]).to include "BAD_ACCESS is not a valid access.  Accepts: manage, create"
      end
    end
    describe '#hyrax_collection_type_id' do
      it { is_expected.to validate_presence_of(:hyrax_collection_type_id) }
    end
  end
end
