# frozen_string_literal: true
RSpec.describe 'catalog/_thumbnail_list_default', type: :view do
  let(:document) { SolrDocument.new(attributes) }
  let(:thumbnail) { instance_double(Blacklight::ThumbnailPresenter, thumbnail_tag: 'THUMBNAIL_TAG') }

  before do
    allow(view).to receive(:document_presenter).and_return(double('presenter', thumbnail: thumbnail))
    allow(view).to receive(:thumbnail_alt_text_for).and_return('alt text')
  end

  context 'with a work' do
    let(:attributes) { { 'id' => 'wk1', 'has_model_ssim' => ['GenericWork'] } }

    it 'wraps the thumbnail in the work list-thumbnail treatment' do
      render 'catalog/thumbnail_list_default', document: document

      expect(rendered).to include 'list-thumbnail'
    end
  end

  context 'with a collection class that does not inherit from Hyrax::PcdmCollection' do
    let(:attributes) { { 'id' => 'col1', 'has_model_ssim' => ['StandaloneCollection'] } }

    before do
      stub_const('StandaloneCollection', Class.new(Hyrax::Resource) do
        def self.name
          'StandaloneCollection'
        end

        def self.to_rdf_representation
          name
        end
      end)
      allow(Hyrax.config).to receive(:collection_model).and_return('StandaloneCollection')
    end

    it 'uses the collection thumbnail treatment rather than the work one' do
      render 'catalog/thumbnail_list_default', document: document

      expect(rendered).not_to include 'list-thumbnail'
    end
  end
end
