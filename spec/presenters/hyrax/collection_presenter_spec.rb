describe Hyrax::CollectionPresenter do
  describe ".terms" do
    subject { described_class.terms }
    it do
      is_expected.to eq [:total_items, :size, :resource_type, :creator,
                         :contributor, :keyword, :rights, :publisher,
                         :date_created, :subject, :language, :identifier,
                         :based_near, :related_url]
    end
  end

  let(:collection) do
    build(:collection,
          id: 'adc12v',
          description: ['a nice collection'],
          based_near: ['Over there'],
          title: ['A clever title'],
          keyword: ['neologism'],
          resource_type: ['Collection'],
          related_url: ['http://example.com/'],
          date_created: ['some date'])
  end
  let(:ability) { double }
  let(:presenter) { described_class.new(solr_doc, ability) }
  let(:solr_doc) { SolrDocument.new(collection.to_solr) }

  # Mock bytes so collection does not have to be saved.
  before { allow(collection).to receive(:bytes).and_return(0) }

  describe "#resource_type" do
    subject { presenter.resource_type }
    it { is_expected.to eq ['Collection'] }
  end

  describe "#terms_with_values" do
    subject { presenter.terms_with_values }
    it do
      is_expected.to eq [:total_items,
                         :size,
                         :resource_type,
                         :keyword,
                         :date_created,
                         :based_near,
                         :related_url]
    end
  end

  describe '#to_s' do
    subject { presenter.to_s }
    it { is_expected.to eq 'A clever title' }
  end

  describe "#title" do
    subject { presenter.title }
    it { is_expected.to eq ['A clever title'] }
  end

  describe '#keyword' do
    subject { presenter.keyword }
    it { is_expected.to eq ['neologism'] }
  end

  describe "#based_near" do
    subject { presenter.based_near }
    it { is_expected.to eq ['Over there'] }
  end

  describe "#related_url" do
    subject { presenter.related_url }
    it { is_expected.to eq ['http://example.com/'] }
  end

  describe '#to_key' do
    subject { presenter.to_key }
    it { is_expected.to eq ['adc12v'] }
  end

  describe "#size", :clean_repo do
    subject { presenter.size }
    it { is_expected.to eq '0 Bytes' }
  end

  describe "#total_items", :clean_repo do
    subject { presenter.total_items }

    context "empty collection" do
      it { is_expected.to eq 0 }
    end

    context "collection with work" do
      let(:work) { create(:work, title: ['unimaginitive title']) }

      before do
        work.member_of_collections << collection
        work.save!
      end

      it { is_expected.to eq 1 }
    end

    context "null members" do
      let(:presenter) { described_class.new(SolrDocument.new(id: '123'), nil) }

      it { is_expected.to eq 0 }
    end
  end

  subject { presenter }
  it { is_expected.to delegate_method(:resource_type).to(:solr_document) }
  it { is_expected.to delegate_method(:based_near).to(:solr_document) }
  it { is_expected.to delegate_method(:related_url).to(:solr_document) }
  it { is_expected.to delegate_method(:identifier).to(:solr_document) }
  it { is_expected.to delegate_method(:date_created).to(:solr_document) }
end
