# frozen_string_literal: true
RSpec.describe 'hyrax/my/_work_action_menu.html.erb' do
  let(:id) { '123' }
  let(:document) { SolrDocument.new(id: id, has_model_ssim: 'GenericWork') }
  let(:user) { build(:user) }

  before do
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:display_trophy_link).and_return("Highlight work on profile")
  end

  context "When the user can transfer and edit works" do
    before do
      allow(view).to receive(:can?).with(:transfer, id).and_return(true)
      allow(view).to receive(:can?).with(:edit, id).and_return(true)
      render 'hyrax/my/work_action_menu', document: document
    end

    it "draws the page" do
      expect(rendered).to have_css '#action-transfer-work'
      expect(rendered).to have_link 'Edit work', href: edit_hyrax_generic_work_path(id)
      expect(rendered).to have_link 'Delete work', href: hyrax_generic_work_path(id)
      expect(rendered).to have_content 'Highlight work on profile'
    end
  end

  context "when the user can't transfer or edit works" do
    before do
      allow(view).to receive(:can?).with(:transfer, id).and_return(false)
      allow(view).to receive(:can?).with(:edit, id).and_return(false)
      render 'hyrax/my/work_action_menu', document: document
    end

    it "draws the page" do
      expect(rendered).not_to have_css '#action-transfer-work'
      expect(rendered).not_to have_css '#action-edit-work'
      expect(rendered).not_to have_css '#action-delete-work'
      expect(rendered).to have_content 'Highlight work on profile'
    end
  end
end
