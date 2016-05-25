describe ContentBlock, type: :model do
  let!(:bilbo) do
    create(:content_block,
           name: ContentBlock::RESEARCHER,
           value: '<h1>Bilbo Baggins</h1>',
           created_at: Time.zone.now)
  end

  let!(:frodo) do
    create(:content_block,
           name: ContentBlock::RESEARCHER,
           value: '<h1>Frodo Baggins</h1>',
           created_at: 2.hours.ago)
  end

  let!(:marketing) do
    create(:content_block,
           name: ContentBlock::MARKETING,
           value: '<h1>Marketing Text</h1>')
  end

  let!(:announcement) do
    create(:content_block,
           name: ContentBlock::ANNOUNCEMENT,
           value: '<h1>Announcement Text</h1>')
  end

  describe '.announcement_text' do
    subject { described_class.announcement_text.value }
    it { is_expected.to eq '<h1>Announcement Text</h1>' }
  end

  describe '.announcement_text=' do
    let(:new_announcement) { '<h2>Foobar</h2>' }
    it 'sets a new announcement_text' do
      described_class.announcement_text = new_announcement
      expect(described_class.announcement_text.value).to eq new_announcement
    end
  end

  describe '.marketing_text' do
    subject { described_class.marketing_text.value }
    it { is_expected.to eq '<h1>Marketing Text</h1>' }
  end

  describe '.marketing_text=' do
    let(:new_marketing) { '<h2>Barbaz</h2>' }
    it 'sets a new marketing_text' do
      described_class.marketing_text = new_marketing
      expect(described_class.marketing_text.value).to eq new_marketing
    end
  end

  describe '.recent_researchers' do
    subject { described_class.recent_researchers }

    it 'returns featured_researcher entries in chronological order' do
      expect(subject.count).to eq 2
      expect(subject).to eq [bilbo, frodo]
    end
  end

  describe '.featured_researcher' do
    subject { described_class.featured_researcher }

    it 'finds the most recent entry for featured_researcher' do
      expect(subject).to eq bilbo
    end

    context 'with no researchers present' do
      before do
        allow(described_class).to receive(:recent_researchers) { described_class.none }
      end
      it 'creates a new researcher' do
        expect(described_class).to receive(:create).with(name: ContentBlock::RESEARCHER)
        described_class.featured_researcher
      end
    end
  end

  describe '.featured_researcher=' do
    let(:new_researcher) { '<h2>Baz Quux</h2>' }
    it 'adds a new featured researcher' do
      expect { described_class.featured_researcher = new_researcher }
        .to change { described_class.recent_researchers.count }.by(1)
      expect(described_class.featured_researcher.value).to eq new_researcher
    end
  end
end
