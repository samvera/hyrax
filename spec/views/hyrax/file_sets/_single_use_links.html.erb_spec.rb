require 'spec_helper'

describe 'hyrax/file_sets/_single_use_links.html.erb', type: :view do
  let(:user)          { create(:user) }
  let(:file_set)      { build(:file_set, user: user, id: "1234") }
  let(:solr_document) { SolrDocument.new(file_set.to_solr) }
  let(:ability)       { Ability.new(user) }
  let(:presenter)     { Hyrax::FileSetPresenter.new(solr_document, ability) }

  context "with no single-use links" do
    before do
      allow(presenter).to receive(:single_use_links).and_return([])
      render 'hyrax/file_sets/single_use_links.html.erb', presenter: presenter
    end
    it "renders a table with no links" do
      expect(rendered).to include("<tr><td>No links have been generated</td></tr>")
    end
  end

  context "with single use links" do
    let(:link)           { SingleUseLink.create(itemId: "1234", downloadKey: "sha2hashb") }
    let(:link_presenter) { Hyrax::SingleUseLinkPresenter.new(link) }
    before do
      controller.params = { id: "1234" }
      allow(presenter).to receive(:single_use_links).and_return([link_presenter])
      render 'hyrax/file_sets/single_use_links.html.erb', presenter: presenter
    end
    it "renders a table with links" do
      expect(rendered).to include("Link sha2ha expires in 23 hours")
    end
  end
end
