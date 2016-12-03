require 'spec_helper'

describe 'hyrax/single_use_links_viewer/show.html.erb' do
  let(:f) do
    file = FileSet.create do |gf|
      gf.apply_depositor_metadata('jill')
    end
    Hydra::Works::AddFileToFileSet.call(file, File.open(fixture_path + '/world.png'), :original_file)
    file
  end

  let(:solr_document) { SolrDocument.new(has_model_ssim: ['FileSet']) }
  let(:ability) { double }

  let(:hash) { "some-dummy-sha2-hash" }

  before do
    assign :asset, f
    assign :download_link, Hyrax::Engine.routes.url_helpers.download_single_use_link_path(hash)
    assign :presenter, Hyrax::FileSetPresenter.new(solr_document, ability)
    view.lookup_context.view_paths.push "#{Hyrax::Engine.root}/app/views/hyrax/base"
    render
  end

  it "contains a download link" do
    expect(rendered).to have_selector "a[href^='/single_use_link/download/']"
  end

  it "has turbolinks disabled in the download link" do
    expect(rendered).to have_selector "a[data-turbolinks^='false'][href^='/single_use_link/download/']"
  end
end
