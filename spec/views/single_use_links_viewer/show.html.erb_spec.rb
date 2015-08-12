require 'spec_helper'

describe 'curation_concerns/single_use_links_viewer/show.html.erb' do
  let(:file) do
    GenericFile.create do |f|
      f.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
      f.label = 'world.png'
      f.apply_depositor_metadata('jill')
    end
  end

  let(:solr_document) { SolrDocument.new(has_model_ssim: ['GenericFile']) }
  let(:ability) { double }

  let(:hash) { "some-dummy-sha2-hash" }

  before do
    assign :asset, file
    assign :download_link, CurationConcerns::Engine.routes.url_helpers.download_single_use_link_path(hash)
    assign :presenter, CurationConcerns::GenericFilePresenter.new(solr_document, ability)
    render
  end

  it "contains a download link" do
    expect(rendered).to have_selector "a[href^='/single_use_link/download/']"
  end

  it "has turbolinks disabled in the download link" do
    expect(rendered).to have_selector "a[data-no-turbolink][href^='/single_use_link/download/']"
  end
end
