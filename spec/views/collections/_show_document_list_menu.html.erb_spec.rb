
describe 'collections/_show_document_list_menu.html.erb', type: :view do
  context 'when user logged in displaying the collections of current user' do
    let(:user) { create :user }
    let(:work) { build(:public_work, user: user, id: "1234") }
    let(:collection) { build(:work, user: user) }

    before { collection.members << work }

    it "displays the action list in individual work drop down" do
      render(partial: 'collections/show_document_list_menu.html.erb', locals: { id: work.id, current_user: user })
      expect(rendered).to have_content 'Select an action'
      expect(rendered).not_to have_content 'Single-Use Link to File'
      expect(rendered).to have_content 'Edit'
      expect(rendered).not_to have_content 'Download File'
      expect(rendered).to have_content 'Highlight Work on Profile'
    end
  end
end
