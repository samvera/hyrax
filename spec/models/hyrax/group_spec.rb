# frozen_string_literal: true

RSpec.describe Hyrax::Group, type: :model do
  let(:name) { 'etaoin' }
  let(:group) { described_class.new(name) }

  describe '.from_agent_key' do
    it 'returns an equivalent group' do
      expect(described_class.from_agent_key(group.agent_key)).to eq group
    end
  end

  describe '#==' do
    let(:other_group) { described_class.new(group.name) }

    it 'correctly determines equality for equivalent groups' do
      expect(other_group).to eq group
    end
  end

  describe '#name' do
    it 'returns the name' do
      expect(group.name).to eq name
    end
  end

  describe '#agent_key' do
    it 'returns the name prefixed with the name prefix' do
      expect(group.agent_key).to eq described_class.name_prefix + group.name
    end
  end

  describe '#to_sipity_agent' do
    subject { group.to_sipity_agent }

    it 'will find or create a Sipity::Agent' do
      expect { subject }.to change { Sipity::Agent.count }.by(1)
    end

    context "when another process makes the agent" do
      before do
        group.to_sipity_agent # create the agent ahead of time
      end

      it "returns the existing agent" do
        expect { subject }.not_to change { Sipity::Agent.count }
      end
    end
  end
end
