require 'spec_helper'

describe SolrDocument, type: :model do
  describe "date_uploaded" do
    before do
      subject['date_uploaded_dtsi'] = '2013-03-14T00:00:00Z'
    end
    it "is a date" do
      expect(subject.date_uploaded).to eq '03/14/2013'
    end
  end

  describe '#to_param' do
    let(:id) { '1v53kn56d' }

    before do
      subject[:id] = id
    end

    it 'returns the object identifier' do
      expect(subject.to_param).to eq id
    end
  end

  describe "document types" do
    class Mimes
      include Hydra::Works::MimeTypes
    end

    context "when mime-type is 'office'" do
      it "is office document" do
        Mimes.office_document_mime_types.each do |type|
          subject['mime_type_tesim'] = [type]
          expect(subject).to be_office_document
        end
      end
    end

    describe "when mime-type is 'video'" do
      it "is office" do
        Mimes.video_mime_types.each do |type|
          subject['mime_type_tesim'] = [type]
          expect(subject).to be_video
        end
      end
    end
  end

  describe '#collection_ids' do
    context 'when the object belongs to collections' do
      subject { described_class.new(id: '123', title_tesim: ['A generic work'], collection_ids_tesim: ['123', '456', '789']) }

      it 'returns the list of collection IDs' do
        expect(subject.collection_ids).to eq ['123', '456', '789']
      end
    end

    context 'when the object does not belong to any collections' do
      subject { described_class.new(id: '123', title_tesim: ['A generic work']) }

      it 'returns an empty array' do
        expect(subject.collection_ids).to eq []
      end
    end
  end

  describe '#collections' do
    context 'when the object belongs to a collection' do
      let(:coll_id) { '456' }
      let(:work_attrs) { { id: '123', title_tesim: ['A generic work'], collection_ids_tesim: [coll_id] } }

      let(:coll_attrs) { { id: coll_id, title_tesim: ['A Collection'] } }

      subject { described_class.new(work_attrs) }

      before do
        ActiveFedora::SolrService.add(coll_attrs)
        ActiveFedora::SolrService.commit
      end

      it 'returns the solr docs for the collections' do
        expect(subject.collections.count).to eq 1
        solr_doc = subject.collections.first
        expect(solr_doc).to be_kind_of described_class
        expect(solr_doc['id']).to eq coll_id
        expect(solr_doc['title_tesim']).to eq coll_attrs[:title_tesim]
      end
    end

    context 'when the object does not belong to any collections' do
      it 'returns empty array' do
        expect(subject.collections).to eq []
      end
    end
  end
end
