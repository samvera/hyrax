RSpec.describe 'hyrax/dashboard/collections/_show_document_list_row.html.erb', type: :view do
  let(:user) { create(:user) }

  let(:work) do
    mock_model(GenericWork, label: 'One Hundred Years of Solitude', date_uploaded: '1999',
                            collection?: true, visibility: 'open',
                            title: ['One Hundred Years of Solitude'],
                            depositor: user,
                            edit_groups: [],
                            creator: ["ggm"])
  end

  let(:collection) { mock_model(Collection, title: 'My awesome collection', members: [work]) }

  context 'when not logged in' do
    before do
      view.blacklight_config = Blacklight::Configuration.new
      assign(:presenter, collection)
      allow(view).to receive(:current_user).and_return(nil)
      allow(work).to receive(:title_or_label).and_return("One Hundred Years of Solitude")
      allow(work).to receive(:edit_people).and_return([])
      allow(view).to receive(:render_other_collection_links).and_return([])
    end

    it "renders collections links" do
      render('show_document_list_row', document: work)
      expect(rendered).not_to have_content 'My awesome collection'
    end

    it "renders works" do
      render('show_document_list_row', document: work)
      expect(rendered).to have_content 'One Hundred Years of Solitude'
      expect(rendered).to have_content('Edit Access:')
    end
  end
end
