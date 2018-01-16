RSpec.describe 'hyrax/collections/_show_parent_collections.html.erb', type: :view do
  let(:collection_doc) do
    {
      id: '999',
      "has_model_ssim" => ["Collection"],
      "title_tesim" => ["Title 1"],
      'date_created_tesim' => '2000-01-01'
    }
  end
  let(:ability) { double }
  let(:solr_document) { SolrDocument.new(collection_doc) }
  let(:presenter) { Hyrax::CollectionPresenter.new(solr_document, ability) }
  let(:collection1) { build(:collection, id: 'col1', title: ['col1']) }
  let(:collection2) { build(:collection, id: 'col2', title: ['col2']) }
  let(:collection3) { build(:collection, id: 'col3', title: ['col3']) }
  let(:collection4) { build(:collection, id: 'col4', title: ['col4']) }
  let(:collection5) { build(:collection, id: 'col5', title: ['col5']) }

  before do
    assign(:presenter, presenter)
    presenter.parent_collections = parent_collections

    allow(collection1).to receive(:persisted?).and_return true
    allow(collection2).to receive(:persisted?).and_return true
    allow(collection3).to receive(:persisted?).and_return true
    allow(collection4).to receive(:persisted?).and_return true
    allow(collection5).to receive(:persisted?).and_return true

    render('show_parent_collections.html.erb', presenter: presenter)
  end

  context 'when parent collection list is empty' do
    let(:parent_collections) { nil }

    it "posts a warning message" do
      expect(rendered).to have_text("There are no visible parent collections.")
    end
  end

  context 'when parent collection list is not empty' do
    let(:parent_collections) { [collection1, collection2, collection3] }

    it "posts the collection's title with a link to the collection" do
      expect(rendered).to have_link(collection1.title.first, visible: true)
      expect(rendered).to have_link(collection2.title.first, visible: true)
      expect(rendered).to have_link(collection3.title.first, visible: true)
      expect(rendered).not_to have_button('show more...')
    end

    xit 'includes a count of the parent collections' do
      # TODO: add test when actual count is added to page
    end
  end

  context 'when parent collection list exceeds parents_to_show' do
    let(:parent_collections) { [collection1, collection2, collection3, collection4, collection5] }

    it "posts the collection's title with a link to the collection" do
      expect(rendered).to have_link(collection1.title.first, visible: true)
      expect(rendered).to have_link(collection2.title.first, visible: true)
      expect(rendered).to have_link(collection3.title.first, visible: true)
      expect(rendered).to have_link(collection4.title.first, visible: false)
      expect(rendered).to have_link(collection5.title.first, visible: false)
      expect(rendered).to have_button('show more...', visible: true)
      expect(rendered).to have_button('...show less', visible: false)
    end
  end
end
