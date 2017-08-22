RSpec.describe Hyrax::Forms::Admin::CollectionTypeParticipantForm do
  let(:collection_type_participant) { build(:collection_type_participant) }
  let(:form) { described_class.new(collection_type_participant: collection_type_participant) }

  subject { form }

  it { is_expected.to delegate_method(:agent_id).to(:collection_type_participant) }
  it { is_expected.to delegate_method(:agent_type).to(:collection_type_participant) }
  it { is_expected.to delegate_method(:access).to(:collection_type_participant) }
end
