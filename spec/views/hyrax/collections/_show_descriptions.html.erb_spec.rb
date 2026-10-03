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

    before do
      allow(presenter).to receive(:total_items).and_return(0)
      assign(:presenter, presenter)
    end

    context 'when the document carries an indexed label' do
      let(:labels) { { "resource_type_label_tesim" => ["Opaque Term"] } }

      it 'shows the label rather than the id it stores' do
        render

        expect(rendered).to have_content 'Opaque Term'
        expect(rendered).not_to have_content 'local_auth_123'
      end
    end

    context 'when the collection was indexed before labels existed' do
      let(:labels) { {} }

      it 'shows the stored id rather than rendering blank' do
        render

        expect(rendered).to have_content 'local_auth_123'
      end
    end
  end
end
