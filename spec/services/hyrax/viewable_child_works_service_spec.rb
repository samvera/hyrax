# frozen_string_literal: true
RSpec.describe Hyrax::ViewableChildWorksService do
  subject(:service) { described_class.new(solr_document: solr_document, ability: ability) }

  let(:solr_document) { SolrDocument.new('id' => 'parent', 'member_ids_ssim' => member_ids) }
  let(:member_ids) { ['child-1', 'child-2'] }
  let(:ability) { Ability.new(nil) }
  let(:num_found) { 1 }

  before do
    allow(Hyrax.config).to receive(:iiif_image_server?).and_return(true)
    allow(Hyrax::SolrService).to receive(:count).and_return(num_found)
  end

  describe '#viewable?' do
    it { expect(service.viewable?).to be true }

    it 'asks Solr once, naming every member in one query' do
      service.viewable?

      expect(Hyrax::SolrService).to have_received(:count)
        .once
        .with(a_string_including('{!terms f=id}child-1,child-2'))
    end

    context 'when no member has a viewable representative' do
      let(:num_found) { 0 }

      it { expect(service.viewable?).to be false }
    end

    context 'when the work has no members' do
      let(:member_ids) { [] }

      it 'is false without querying Solr' do
        expect(service.viewable?).to be false
        expect(Hyrax::SolrService).not_to have_received(:count)
      end
    end

    context 'when no media type is viewable' do
      before do
        allow(Hyrax.config).to receive(:iiif_image_server?).and_return(false)
        allow(Flipflop).to receive(:iiif_av?).and_return(false)
        allow(Flipflop).to receive(:iiif_pdf?).and_return(false)
      end

      it 'is false without querying Solr' do
        expect(service.viewable?).to be false
        expect(Hyrax::SolrService).not_to have_received(:count)
      end
    end
  end
end
