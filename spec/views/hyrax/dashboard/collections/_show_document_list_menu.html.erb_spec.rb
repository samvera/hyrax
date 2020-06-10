# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_show_document_list_menu.html.erb', type: :view do
  context 'when user is viewing a collection' do
    let(:user) { create :user }
    let(:ability) { instance_double("Ability") }
    let(:document) { SolrDocument.new(id: '1234') }

    before do
      view.extend Hyrax::TrophyHelper
      allow(document).to receive(:to_model).and_return(stub_model(GenericWork))
      allow(controller).to receive(:current_ability).and_return(ability)
    end

    it "displays the action list in a drop down for an individual work the user can edit" do
      allow(ability).to receive(:can?).with(:edit, document).and_return(true)
      render('show_document_list_menu', document: document, current_user: user)
      expect(rendered).to have_content 'Select'
      expect(rendered).to have_content 'Edit'
      expect(rendered).not_to have_content 'Download File'
      expect(rendered).to have_content 'Highlight Work on Profile'
    end

    it "displays the action list in a drop down for an individual work the user cannot edit" do
      allow(ability).to receive(:can?).with(:edit, document).and_return(false)
      render('show_document_list_menu', document: document, current_user: user)
      expect(rendered).to have_content 'Select'
      expect(rendered).not_to have_content 'Edit'
      expect(rendered).not_to have_content 'Download File'
      expect(rendered).to have_content 'Highlight Work on Profile'
    end
  end
end
