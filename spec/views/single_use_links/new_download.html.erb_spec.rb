require 'spec_helper'

describe 'curation_concerns/single_use_links/new_download.html.erb' do
  let(:user) { FactoryGirl.find_or_create(:jill) }
  let(:file) do
    GenericFile.create do |f|
      f.add_file(File.open(fixture_path + '/world.png'), path: 'content', original_name: 'world.png')
      f.label = 'world.png'
      f.apply_depositor_metadata(user)
    end
  end

  let(:hash) { "some-dummy-sha2-hash" }

  before do
    assign :asset, file
    assign :link, CurationConcerns::Engine.routes.url_helpers.download_single_use_link_path(hash)
    render
  end

  it "has the download link" do
    expect(rendered).to have_selector "a.download-link"
  end

  it "has turbolinks disabled in the download link" do
    expect(rendered).to have_selector "a.download-link[data-no-turbolink]"
  end
end
