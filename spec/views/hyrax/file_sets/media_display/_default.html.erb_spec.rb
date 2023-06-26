# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/media_display/_default.html.erb', type: :view do
  let(:ability)  { double(Ability) }
  let(:file_set) { stub_model(FileSet, parent: parent) }
  let(:parent) { double }
  let(:link) { true }
  let(:work_solr_document) do
    SolrDocument.new(id: '900', title_tesim: ['My Title'])
  end
  let(:parent_presenter) { Hyrax::WorkShowPresenter.new(work_solr_document, ability) }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    allow(ability).to receive(:can?).with(:download, file_set).and_return(true)
    allow(view).to receive(:workflow_restriction?).with(parent).and_return(false)
    allow(Hyrax.config).to receive(:display_media_download_link?).and_return(link)
    assign(:presenter, parent_presenter)
    render 'hyrax/file_sets/media_display/default', file_set: file_set
  end

  it "draws the view with the link" do
    expect(rendered).to have_css('div.no-preview')
    expect(rendered).to have_css('a', text: 'Download the file')
  end

  it "includes google analytics data in the download link" do
    expect(rendered).to have_css('a#file_download')
    expect(rendered).to have_selector("a[data-label=\"#{file_set.id}\"]")
  end

  context "no download links" do
    let(:link) { false }

    it "draws the view without the link" do
      expect(rendered).to have_css('div.no-preview')
      expect(rendered).not_to have_css('a', text: 'Download the file')
    end
  end
end
