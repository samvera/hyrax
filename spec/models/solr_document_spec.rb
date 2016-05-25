describe ::SolrDocument, type: :model do
  let(:document) { described_class.new(attributes) }
  let(:attributes) { {} }

  describe "date_uploaded" do
    let(:attributes) { { 'date_uploaded_dtsi' => '2013-03-14T00:00:00Z' } }
    subject { document.date_uploaded }
    it { is_expected.to eq '03/14/2013' }

    context "when an invalid type is provided" do
      let(:attributes) { { 'date_uploaded_dtsi' => 'Test' } }
      it "logs parse errors" do
        expect(ActiveFedora::Base.logger).to receive(:info).with(/Unable to parse date.*/)
        subject
      end
    end
  end

  describe "create_date" do
    let(:attributes) { { 'system_create_dtsi' => '2013-03-14T00:00:00Z' } }
    subject { document.create_date }
    it { is_expected.to eq '03/14/2013' }

    context "when an invalid type is provided" do
      let(:attributes) { { 'system_create_dtsi' => 'Test' } }
      it "logs parse errors" do
        expect(ActiveFedora::Base.logger).to receive(:info).with(/Unable to parse date.*/)
        subject
      end
    end
  end

  describe "resource_type" do
    let(:attributes) { { 'resource_type_tesim' => ['Image'] } }
    subject { document.resource_type }
    it { is_expected.to eq ['Image'] }
  end

  describe '#to_param' do
    let(:id) { '1v53kn56d' }
    let(:attributes) { { id: id } }
    subject { document.to_param }
    it { is_expected.to eq id }
  end

  describe "document types" do
    class Mimes
      include Hydra::Works::MimeTypes
    end

    Mimes.office_document_mime_types.each do |type|
      context "when mime-type is #{type}" do
        let(:attributes) { { 'mime_type_ssi' => type } }
        subject { document }
        it { is_expected.to be_office_document }
      end
    end

    Mimes.video_mime_types.each do |type|
      context "when mime-type is #{type}" do
        let(:attributes) { { 'mime_type_ssi' => type } }
        subject { document }
        it { is_expected.to be_video }
      end
    end
  end

  describe '#collection_ids' do
    subject { document.collection_ids }
    context 'when the object belongs to collections' do
      let(:attributes) { { id: '123',
                           title_tesim: ['A generic work'],
                           collection_ids_tesim: ['123', '456', '789'] } }
      it { is_expected.to eq ['123', '456', '789'] }
    end

    context 'when the object does not belong to any collections' do
      let(:attributes) { { id: '123',
                           title_tesim: ['A generic work'] } }

      it { is_expected.to eq [] }
    end
  end

  describe '#collections' do
    subject { document.collections }
    context 'when the object belongs to a collection' do
      let(:coll_id) { '456' }
      let(:attributes) { { id: '123',
                           title_tesim: ['A generic work'],
                           collection_ids_tesim: [coll_id] } }

      let(:coll_attrs) { { id: coll_id, title_tesim: ['A Collection'] } }

      before do
        ActiveFedora::SolrService.add(coll_attrs)
        ActiveFedora::SolrService.commit
      end

      it 'returns the solr docs for the collections' do
        expect(subject.count).to eq 1
        solr_doc = subject.first
        expect(solr_doc).to be_kind_of described_class
        expect(solr_doc['id']).to eq coll_id
        expect(solr_doc['title_tesim']).to eq coll_attrs[:title_tesim]
      end
    end

    context 'when the object does not belong to any collections' do
      it { is_expected.to eq [] }
    end
  end

  describe "#height" do
    let(:attributes) { { height_is: '444' } }
    subject { document.height }
    it { is_expected.to eq '444' }
  end

  describe "#width" do
    let(:attributes) { { width_is: '555' } }
    subject { document.width }
    it { is_expected.to eq '555' }
  end
end
