# frozen_string_literal: true
RSpec.describe 'hyrax/single_use_links_viewer/show.html.erb' do
  let(:solr_document) { SolrDocument.new(has_model_ssim: ['FileSet']) }
  let(:ability) { double }

  let(:hash) { "some-dummy-sha2-hash" }

  before do
    assign :download_link, Hyrax::Engine.routes.url_helpers.download_single_use_link_path(hash)
    assign :presenter, Hyrax::FileSetPresenter.new(solr_document, ability)
    view.lookup_context.append_view_paths(["#{Hyrax::Engine.root}/app/views/hyrax/base"])
    render
  end

  it "contains a download link" do
    expect(rendered).to have_selector "a[href^='/single_use_link/download/']"
  end
end
