RSpec.describe 'hyrax/collections/_show_parent_collections.html.erb', type: :view do
  let(:collection) { build(:named_collection, id: '123') }

  context 'when parent collection list is empty' do
    let(:parentcollection) { nil }

    before do
      assign(:parent_collections, parentcollection)
    end

    it "posts a warning message" do
      render('show_parent_collections.html.erb', collection: parentcollection)
      expect(rendered).to have_text("There are no visible parent collections.")
    end
  end

  context 'when parent collection list is not empty' do
    let(:parentcollection) { [collection] }

    before do
      assign(:parent_collections, parentcollection)
      assign(:document, collection)
      allow(collection).to receive(:title_or_label).and_return(collection.title)
      allow(collection).to receive(:persisted?).and_return true
      render('show_parent_collections.html.erb', collection: parentcollection)
    end

    it "posts the collection's title with a link to the collection" do
      expect(rendered).to have_link(collection.title.first)
    end

    xit 'includes a count of the parent collections' do
      # TODO: add test when actual count is added to page
    end
  end
end
