# frozen_string_literal: true
RSpec.describe Hyrax::ParentCollectionSearchBuilder do
  let(:solr_params) { { fq: [] } }
  let(:item) { double(id: '12345', member_of_collection_ids: ['col1']) }
  let(:builder) { described_class.new(solr_params, context) }
  let(:context) { double("context", blacklight_config: CatalogController.blacklight_config, item: item, search_state_class: nil) }

  describe '#include_item_ids' do
    let(:subject) { builder.include_item_ids(solr_params) }

    it 'updates solr_parameters[:fq]' do
      subject
      expect(solr_params[:fq]).to include("{!terms f=id}col1")
    end
  end
end
