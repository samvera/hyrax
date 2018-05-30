RSpec.describe 'hyrax/collections/_show_document_list_row.html.erb', type: :view do
  let(:user) { create(:user) }

  let(:work) do
    create(:work, user: user, creator: ["ggm"], title: ['One Hundred Years of Solitude'])
  end

  let(:collection) { mock_model(Collection, title: 'My awesome collection', members: [work]) }

  context 'when not logged in' do
    before do
      view.blacklight_config = Blacklight::Configuration.new
      allow(view).to receive(:current_user).and_return(nil)
      allow(work).to receive(:title_or_label).and_return("One Hundred Years of Solitude")
      allow(work).to receive(:edit_people).and_return([])
      allow(view).to receive(:render_collection_links).and_return("collections: #{collection.title}")
    end

    it "renders collections links" do
      render('hyrax/collections/show_document_list_row.html.erb', document: work)
      expect(rendered).to have_content 'My awesome collection'
    end

    it "renders works" do
      render('hyrax/collections/show_document_list_row.html.erb', document: work)
      expect(rendered).to have_content 'One Hundred Years of Solitude'
      expect(rendered).not_to have_content('Edit Access:')
    end
  end
end
