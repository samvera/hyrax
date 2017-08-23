RSpec.describe 'hyrax/dashboard/collections/_show_descriptions.html.erb', type: :view do
  context 'displaying a custom collection' do
    let(:collection_size) { 123_456_678 }
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
      allow(presenter).to receive(:size).and_return("118 MB")
      assign(:presenter, presenter)
    end

    it "draws the metadata fields for collection" do
      render
      expect(rendered).to have_content 'Date Created'
      expect(rendered).to include('itemprop="dateCreated"')
      expect(rendered).to have_content 'Total works'
      expect(rendered).to have_content '2'
      expect(rendered).to have_content 'Size'
      expect(rendered).to have_content '118 MB'
    end
  end
end
