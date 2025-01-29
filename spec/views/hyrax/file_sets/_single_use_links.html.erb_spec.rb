# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/_single_use_links.html.erb', type: :view do
  let(:user)          { create(:user) }
  let(:solr_document) { SolrDocument.new(id: '1234', 'has_model_ssim' => 'FileSet') }
  let(:ability)       { Ability.new(user) }
  let(:presenter)     { Hyrax::FileSetPresenter.new(solr_document, ability) }

  context "with no single-use links" do
    before do
      allow(presenter).to receive(:single_use_links).and_return([])
      render 'hyrax/file_sets/single_use_links', presenter: presenter
    end
    it "renders a table with no links" do
      expect(rendered).to include("<tr><td>No links have been generated</td></tr>")
    end
  end

  context "with single use links" do
    let(:link)           { SingleUseLink.create(item_id: "1234", download_key: "sha2hashb") }
    let(:link_presenter) { Hyrax::SingleUseLinkPresenter.new(link) }

    before do
      controller.params = { id: "1234" }
      allow(presenter).to receive(:single_use_links).and_return([link_presenter])
      render 'hyrax/file_sets/single_use_links', presenter: presenter
    end
    it "renders a table with links" do
      expect(rendered).to include("Link sha2ha expires in 23 hours")
    end

    it "renders the single use link button" do
      expect(rendered).to have_link("Create Single-Use Link")
    end
  end
end
