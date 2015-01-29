require 'spec_helper'

describe ContentBlock, :type => :model do

  let(:bilbo) { ContentBlock.create!(
    name: ContentBlock::RESEARCHER,
    value: '<h1>Bilbo Baggins</h1>',
    created_at: Time.now)
  }

  let(:frodo) { ContentBlock.create!(
    name: ContentBlock::RESEARCHER,
    value: '<h1>Frodo Baggins</h1>',
    created_at: 2.hours.ago)
  }

  let(:marketing) { ContentBlock.create!(
    name: ContentBlock::MARKETING,
    value: '<h1>Marketing Text</h1>')
  }

  describe '.recent_researchers' do
    before { frodo; bilbo; marketing }
    subject { ContentBlock.recent_researchers }

    it 'returns featured_researcher entries in chronological order' do
      expect(ContentBlock.count).to eq 3
      expect(subject).to eq [bilbo, frodo]
    end
  end

  describe '.featured_researcher' do
    before { frodo; bilbo; marketing }
    subject { ContentBlock.featured_researcher }

    it 'finds the most recent entry for featured_researcher' do
      expect(subject).to eq bilbo
    end
  end

end
