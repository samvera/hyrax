# frozen_string_literal: true
RSpec.describe 'hyrax/collections/_show_descriptions.html.erb', type: :view do
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

    context 'with a contributor' do
      let(:collection) { super().merge('contributor_tesim' => ['Ada Lovelace']) }

      it 'links the contributor through the facet the catalog uses for it' do
        render

        href = CGI.unescape(Capybara.string(rendered).find_link('Ada Lovelace')['href'])
        expect(href).to include('f[contributor_sim][]=Ada Lovelace')
      end
    end
  end

  context 'displaying a controlled term' do
    let(:collection) do
      {
        id: '999',
        "has_model_ssim" => ["Collection"],
        "title_tesim" => ["Title 1"],
        "resource_type_tesim" => ["local_auth_123"]
      }.merge(labels)
    end
    let(:solr_document) { SolrDocument.new(collection) }
    let(:presenter) { Hyrax::CollectionPresenter.new(solr_document, double) }

    let(:config) do
      CatalogController.blacklight_config.deep_copy.tap do |blacklight|
        blacklight.add_facet_field('resource_type_label_sim') unless blacklight.facet_fields.key?('resource_type_label_sim')
      end
    end
    let(:href) { CGI.unescape(Capybara.string(rendered).find_link(link_text)['href']) }

    before do
      allow(presenter).to receive(:total_items).and_return(0)
      allow(CatalogController).to receive(:new).and_return(instance_double(CatalogController, blacklight_config: config))
      assign(:presenter, presenter)
    end

    context 'when the document carries an indexed label' do
      let(:labels) { { "resource_type_label_tesim" => ["Opaque Term"] } }

      it 'shows the label rather than the id it stores' do
        render

        expect(rendered).to have_content 'Opaque Term'
        expect(rendered).not_to have_content 'local_auth_123'
      end

      context 'with the catalog faceting it on labels' do
        let(:link_text) { 'Opaque Term' }

        it 'links the label through the label facet' do
          render

          expect(href).to include('f[resource_type_label_sim][]=Opaque Term')
        end
      end
    end

    context 'when the collection was indexed before labels existed' do
      let(:labels) { {} }

      it 'shows the stored id rather than rendering blank' do
        render

        expect(rendered).to have_content 'local_auth_123'
      end

      context 'with the catalog faceting it on labels' do
        let(:link_text) { 'local_auth_123' }

        it 'links the stored id through its own facet' do
          render

          expect(href).to include('f[resource_type_sim][]=local_auth_123')
        end
      end
    end
  end
end
