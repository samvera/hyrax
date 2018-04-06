RSpec.describe 'hyrax/file_sets/media_display/_video.html.erb', type: :view do
  let(:file_set) { stub_model(FileSet) }
  let(:config) { double }
  let(:link) { true }

  before do
    allow(Hyrax.config).to receive(:display_media_download_link?).and_return(link)
    render 'hyrax/file_sets/media_display/video', file_set: file_set
  end

  it "draws the view with the link" do
    expect(rendered).to have_selector("video")
    expect(rendered).to have_css('a', text: 'Download video')
  end

  it "includes google analytics data in the download link" do
    expect(rendered).to have_css('a#file_download')
    expect(rendered).to have_selector("a[data-label=\"#{file_set.id}\"]")
  end

  context "no download links" do
    let(:link) { false }

    it "draws the view without the link" do
      expect(rendered).to have_selector("video")
      expect(rendered).not_to have_css('a', text: 'Download video')
    end
  end
end
