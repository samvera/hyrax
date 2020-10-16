# frozen_string_literal: true

RSpec.describe Hyrax::SolrDocumentBehavior do
  subject(:solr_document) { solr_document_class.new(solr_hash) }
  let(:solr_hash) { {} }

  let(:solr_document_class) do
    Class.new do
      include Blacklight::Solr::Document
      include Hyrax::SolrDocumentBehavior
    end
  end

  describe '#itemtype' do
    it 'defaults to CreativeWork' do
      expect(solr_document.itemtype).to eq 'http://schema.org/CreativeWork'
    end

    context 'for a Video' do
      let(:solr_hash) { { resource_type_tesim: 'Video' } }

      it 'is of type Video' do
        expect(solr_document.itemtype).to eq 'http://schema.org/VideoObject'
      end
    end
  end

  describe '#title_or_label' do
    it 'defaults to nil' do
      expect(solr_document.title_or_label).to be_nil
    end

    context 'with a label' do
      let(:solr_hash) { { label_tesim: 'label' } }

      it 'gives the label' do
        expect(solr_document.title_or_label).to eq 'label'
      end
    end

    context 'with a title' do
      let(:solr_hash) { { title_tesim: 'title' } }

      it 'gives the title' do
        expect(solr_document.title_or_label).to eq 'title'
      end

      context 'and a label' do
        let(:solr_hash) { { title_tesim: 'title', label_tesim: 'label' } }

        it 'gives the title' do
          expect(solr_document.title_or_label).to eq 'title'
        end
      end
    end

    context 'with several titles' do
      let(:solr_hash) { { title_tesim: ['title1', 'title2'] } }

      it 'gives the title' do
        expect(solr_document.title_or_label).to eq 'title1, title2'
      end
    end
  end

  describe '#to_s' do
    it 'defaults to empty string' do
      expect(solr_document.to_s).to eq ''
    end
  end
end
