# frozen_string_literal: true
RSpec.describe 'catalog/_index_header_list_default', type: :view do
  let(:document) { SolrDocument.new(attributes) }
  let(:badge) { 'COLLECTION_TYPE_BADGE' }

  before do
    allow(view).to receive(:current_ability).and_return(double('Ability'))
    allow(Hyrax::CollectionPresenter).to receive(:new).and_return(
      instance_double(Hyrax::CollectionPresenter, collection_type_badge: badge)
    )
  end

  context 'with a work' do
    let(:attributes) { { 'id' => 'wk1', 'title_tesim' => ['A Work'], 'has_model_ssim' => ['GenericWork'] } }

    it 'renders the title without a collection type badge' do
      render 'catalog/index_header_list_default', document: document

      expect(rendered).to include 'A Work'
      expect(rendered).not_to include badge
    end
  end

  context 'with the configured collection class' do
    let(:attributes) do
      { 'id' => 'col1',
        'title_tesim' => ['A Collection'],
        'has_model_ssim' => [Hyrax.config.collection_class.to_rdf_representation] }
    end

    it 'renders the collection type badge' do
      render 'catalog/index_header_list_default', document: document

      expect(rendered).to include badge
    end
  end

  context 'with a collection class that does not inherit from Hyrax::PcdmCollection' do
    let(:attributes) { { 'id' => 'col2', 'title_tesim' => ['Standalone'], 'has_model_ssim' => ['StandaloneCollection'] } }

    before do
      stub_const('StandaloneCollection', Class.new(Hyrax::Resource) do
        def self.name
          'StandaloneCollection'
        end

        def self.to_rdf_representation
          name
        end

        def self._hyrax_default_name_class
          Hyrax::CollectionName
        end
      end)
      allow(Hyrax.config).to receive(:collection_model).and_return('StandaloneCollection')
    end

    it 'renders the collection type badge' do
      render 'catalog/index_header_list_default', document: document

      expect(rendered).to include badge
    end
  end
end
