# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/media_display/_audio.html.erb', type: :view do
  let(:ability) { double(Ability) }
  let(:request) { double('request', base_url: 'test.host') }
  let(:file_set) { Hyrax::FileSetPresenter.new(SolrDocument.new(id: 'foo'), ability, request) }
  let(:link) { true }
  let(:work_solr_document) do
    SolrDocument.new(id: '900', title_tesim: ['My Title'])
  end
  let(:parent_presenter) { Hyrax::WorkShowPresenter.new(work_solr_document, ability) }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(ability).to receive(:can?).with(:download, file_set).and_return(true)
    allow(Hyrax.config).to receive(:display_media_download_link?).and_return(link)
    allow(file_set).to receive(:parent).and_return(parent_presenter)
    allow(view).to receive(:workflow_restriction?).with(parent_presenter).and_return(false)
    assign(:presenter, parent_presenter)
  end

  context 'with no transcript' do
    before do
      render 'hyrax/file_sets/media_display/audio', file_set: file_set
    end

    it "draws the view with the link" do
      expect(rendered).to have_selector("audio")
      expect(rendered).to have_css('a', text: 'Download audio')
    end

    it "includes google analytics data in the download link" do
      expect(rendered).to have_css('a#file_download')
      expect(rendered).to have_selector("a[data-label=\"#{file_set.id}\"]")
    end

    it "does not render a <track> tag" do
      expect(rendered).not_to have_css('track')
    end
  end

  context 'with transcript(s)' do
    let(:transcript) { SolrDocument.new(title_tesim: ['Title'], original_file_id_ssi: ["foobar"]) }

    before do
      allow(file_set).to receive(:transcripts).and_return [transcript]
      allow(file_set).to receive(:language_code).and_return "fr"
    end

    it "renders a valid <track> tag" do
      render 'hyrax/file_sets/media_display/audio', file_set: file_set
      track = Capybara::Node::Simple.new(rendered).find('track')
      expect(track[:src]).to eq "http://test.host/transcripts/foobar.vtt"
      expect(track[:srclang]).to eq "fr"
      expect(track[:label]).to eq "Title"
    end
  end

  context "no download links" do
    let(:link) { false }

    it "draws the view without the link" do
      render 'hyrax/file_sets/media_display/audio', file_set: file_set
      expect(rendered).to have_selector("audio")
      expect(rendered).not_to have_css('a', text: 'Download audio')
    end
  end
end
