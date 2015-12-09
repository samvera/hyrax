require 'spec_helper'

describe 'collections/_show_document_list_menu.html.erb', type: :view do
  context 'when user logged in displaying the collections of current user' do
    let(:user) { create :user }

    let!(:work) {
      GenericWork.create! do |work|
        work.title = ['work title abc']
        work.apply_depositor_metadata(user.user_key)
        work.read_groups = ['public']
      end
    }

    let!(:collection) {
      Collection.create do |f|
        f.title = 'collection title abc'
        f.apply_depositor_metadata(user.user_key)
        f.read_groups = ['public']
        f.members = [work]
      end
    }

    before do
      allow(view).to receive(:current_user).and_return(user)
      allow(collection).to receive(:title).and_return('collection title abc')
      allow(work).to receive(:title).and_return('work title abc')
    end

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
