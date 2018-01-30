RSpec.describe 'hyrax/dashboard/collections/_subcollection_list.html.erb', type: :view do
  let(:collection) { build(:named_collection, id: '123') }

  context 'when subcollection list is empty' do
    let(:subcollection) { nil }

    before do
      assign(:subcollection_docs, subcollection)
    end

    it "posts a warning message" do
      render('subcollection_list.html.erb', collection: subcollection)
      expect(rendered).to have_text("There are no visible subcollections.")
    end
  end

  context 'when subcollection list is not empty' do
    let(:subcollection) { [collection] }

    before do
      assign(:subcollection_docs, subcollection)
      assign(:document, collection)
    end

    it "posts the collection's title with a link to the collection" do
      allow(collection).to receive(:title_or_label).and_return(collection.title)
      # make the collection "persisted" so the route returned is valid for show
      allow(collection).to receive(:persisted?).and_return true
      render('subcollection_list.html.erb', collection: subcollection)
      expect(rendered).to have_link(collection.title.to_s)
    end

    xit 'includes a count of the subcollection members' do
      # TODO: add test when actual count is added to page
    end
  end
end
