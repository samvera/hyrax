require 'spec_helper'

describe ContentBlock, type: :model do
  let(:bilbo) { described_class.create!(
    name: ContentBlock::RESEARCHER,
    value: '<h1>Bilbo Baggins</h1>',
    created_at: Time.zone.now)
  }

  let(:frodo) { described_class.create!(
    name: ContentBlock::RESEARCHER,
    value: '<h1>Frodo Baggins</h1>',
    created_at: 2.hours.ago)
  }

  let(:marketing) { described_class.create!(
    name: ContentBlock::MARKETING,
    value: '<h1>Marketing Text</h1>')
  }

  describe '.recent_researchers' do
    before do
      frodo
      bilbo
      marketing
    end
    subject { described_class.recent_researchers }

    it 'returns featured_researcher entries in chronological order' do
      expect(described_class.count).to eq 3
      expect(subject).to eq [bilbo, frodo]
    end
  end

  describe '.featured_researcher' do
    before do
      frodo
      bilbo
      marketing
    end
    subject { described_class.featured_researcher }

    it 'finds the most recent entry for featured_researcher' do
      expect(subject).to eq bilbo
    end
  end
end
