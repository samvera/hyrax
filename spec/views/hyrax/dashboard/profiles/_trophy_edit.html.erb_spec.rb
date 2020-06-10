# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/profiles/_trophy_edit.html.erb', type: :view do
  let(:user) { stub_model(User, user_key: 'mjg') }
  let(:page) { Capybara::Node::Simple.new(rendered) }

  before do
    allow(view).to receive(:signed_in?).and_return(true)
    allow(view).to receive(:current_user).and_return(user)
    assign(:user, user)
  end

  context "when there are no highlighted works" do
    before do
      assign(:trophies, [])
      render 'edit_primary'
    end

    it "has no trophy" do
      expect(page).not_to have_css('a#remove_trophy_help')
      expect(page).not_to have_content('Remove Highlight Designation')
    end
  end

  context "when there are highlighted works" do
    let(:solr_document) { SolrDocument.new(id: 'abc123', has_model_ssim: 'GenericWork', title_tesim: ['Title']) }

    before do
      assign(:trophies, [Hyrax::TrophyPresenter.new(solr_document)])
      render 'edit_primary'
    end

    it "has trophy" do
      expect(page).to have_css('a#remove_trophy_help')
      expect(page).to have_selector("#remove_trophy_abc123")
    end
  end
end
