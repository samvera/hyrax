
describe 'collections/_show_document_list_menu.html.erb', type: :view do
  context 'when user logged in displaying the collections of current user' do
    let(:user) { create :user }
    let(:document) { SolrDocument.new(id: '1234') }
    before do
      allow(document).to receive(:to_model).and_return(stub_model(GenericWork))
    end

    it "displays the action list in individual work drop down" do
      render('collections/show_document_list_menu.html.erb', document: document, current_user: user)
      expect(rendered).to have_content 'Select an action'
      expect(rendered).not_to have_content 'Single-Use Link to File'
      expect(rendered).to have_content 'Edit'
      expect(rendered).not_to have_content 'Download File'
      expect(rendered).to have_content 'Highlight Work on Profile'
    end
  end
end
