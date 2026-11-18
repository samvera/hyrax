# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_show_descriptions.html.erb', type: :view do
  context 'displaying a custom collection' do
    let(:collection) do
      {
        id: '999',
        "has_model_ssim" => ["Collection"],
        "title_tesim" => ["Title 1"],
        'date_created_tesim' => '2000-01-01'
      }
    end
    let(:ability) { double }
    let(:solr_document) { SolrDocument.new(collection) }
    let(:presenter) { Hyrax::CollectionPresenter.new(solr_document, ability) }

    before do
      allow(presenter).to receive(:total_items).and_return(2)
      assign(:presenter, presenter)
    end

    it "draws the metadata fields for collection" do
      render
      expect(rendered).to have_content 'Date Created'
      expect(rendered).to include('itemprop="dateCreated"')
      expect(rendered).to have_content 'Total items'
      expect(rendered).to have_content '2'
    end
  end

  context 'with Hyrax.config.collection_terms on a collection saved under the flexible profile' do
    let(:solr_document) do
      SolrDocument.new('id' => 'c1', 'has_model_ssim' => [Hyrax.config.collection_model], 'schema_version_ssi' => '1',
                       'title_tesim' => ['Harbor Records'], 'abstract_tesim' => ['Maps of the harbor.'], 'call_number_tesim' => ['MS.0951'])
    end
    let(:presenter) { Hyrax::CollectionPresenter.new(solr_document, Ability.new(nil)) }

    before do
      on_collections = { 'class' => [Hyrax.config.collection_model] }
      allow(Hyrax::FlexibleSchema).to receive_messages(
        current_version: { 'properties' => {
          'abstract' => { 'available_on' => on_collections, 'indexing' => ['abstract_tesim'], 'data_type' => 'array',
                          'display_label' => { 'default' => 'Summary' }, 'view' => { 'html_dl' => true } },
          'call_number' => { 'available_on' => on_collections, 'indexing' => ['call_number_tesim'], 'data_type' => 'array', 'view' => { 'html_dl' => true } }
        } },
        current_schema_id: 1
      )
      allow(view).to receive(:current_user).and_return(nil)
      allow(Hyrax.config).to receive(:collection_terms).and_return(%i[call_number title abstract])
      assign(:presenter, presenter)
    end

    after do
      %i[abstract call_number].each do |reader|
        Hyrax::CollectionPresenter.send(:remove_method, reader) if Hyrax::CollectionPresenter.method_defined?(reader, false)
      end
      Hyrax::CollectionPresenter.profile_readers.clear
    end

    it "lists the configured fields the profile has, in order, with the profile's labels" do
      render

      expect(Capybara.string(rendered).all('dt').map { |term| term.text.strip }).to eq ['Call number', 'Summary']
      expect(rendered).to have_css('dd', text: 'MS.0951')
    end
  end
end
