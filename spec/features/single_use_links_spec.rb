require 'spec_helper'

describe "Create and use single-use links", type: :feature do
  include Warden::Test::Helpers
  Warden.test_mode!
  include Sufia::Engine.routes.url_helpers

  let(:user) { create(:user) }
  let(:file) do
    FileSet.create do |fs|
      fs.label = 'world.png'
      fs.apply_depositor_metadata(user)
    end
  end

  let(:binary) { File.open(fixture_path + '/world.png') }

  before do
    Hydra::Works::AddFileToFileSet.call(file, binary, :original_file, versioning: false)
  end

  before do
    login_as user
  end

  it "generates a single-use link to show the record" do
    visit curation_concerns.generate_show_single_use_link_path(id: file)
    expect(page).to have_css '.single-use-link a'
    find('.single-use-link a').click
    expect(page).to have_content 'world.png'
    expect(page).to have_content "Download (can only be used once)"
  end

  describe "download link" do
    it "downloads the file contents" do
      visit curation_concerns.generate_download_single_use_link_path(id: file)
      expect(page).to have_css '.download-link'
      find('.download-link').click
      expected_content = ActiveFedora::Base.find(file.id).original_file.content
      expect(page.source).to eq expected_content
    end
  end
end
