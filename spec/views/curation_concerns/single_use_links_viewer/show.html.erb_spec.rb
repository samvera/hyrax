require 'spec_helper'

describe 'curation_concerns/single_use_links_viewer/show.html.erb' do
  let(:ability) { double }
  let(:model) { stub_model(FileSet, title: ['world.png']) }
  let(:solr_document) { SolrDocument.new(model.to_solr) }
  let(:presenter) { CurationConcerns::FileSetPresenter.new(solr_document, ability) }
  let(:download_link) { '/a_path' }
  before do
    assign(:presenter, presenter)
    assign(:download_link, download_link)
    view.lookup_context.view_paths.push 'app/views/curation_concerns/base'
    render
  end

  it "renders the page" do
    expect(rendered).to have_selector 'h1', text: 'world.png'
  end
end
