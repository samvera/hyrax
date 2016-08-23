require 'spec_helper'

describe 'curation_concerns/file_sets/mdeia_display/_default.html.erb', type: :view do
  let(:file_set) { stub_model(FileSet) }
  let(:config) { double }
  let(:link) { true }

  before do
    allow(CurationConcerns.config).to receive(:display_media_download_link).and_return(link)
    render 'curation_concerns/file_sets/media_display/default', file_set: file_set
  end

  it "draws the view with the link" do
    expect(rendered).to have_css('div.no-preview')
    expect(rendered).to have_css('a', text: 'Download the file')
  end

  context "no download links" do
    let(:link) { false }

    it "draws the view without the link" do
      expect(rendered).to have_css('div.no-preview')
      expect(rendered).not_to have_css('a', text: 'Download the file')
    end
  end
end
