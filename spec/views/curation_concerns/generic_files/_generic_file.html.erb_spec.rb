require 'spec_helper'

describe 'curation_concerns/generic_files/_generic_file.html.erb' do
  let(:solr_document) { SolrDocument.new(id: '999',
                                         has_model_ssim: ['GenericFile'],
                                         representative_tesim: ["999"],
                                         title_tesim: ["My File"]) }

  # Ability is checked in GenericFilePresenter#link_name
  let(:ability) { double(can?: true) }
  let(:presenter) { CurationConcerns::GenericFilePresenter.new(solr_document, ability) }

  before do
    assign(:presenter, presenter)
    allow(view).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
    allow(view).to receive(:current_search_session).and_return nil
    allow(view).to receive(:search_session).and_return({})
    # abilities called in _actions.html.erb
    allow(view).to receive(:can?).with(:read, kind_of(String)).and_return(true)
    allow(view).to receive(:can?).with(:edit, kind_of(String)).and_return(true)
    allow(view).to receive(:can?).with(:destroy, String).and_return(true)
    render 'curation_concerns/generic_files/generic_file.html.erb', generic_file: presenter
  end

  it 'renders the view' do
    # A thumbnail
    expect(rendered).to have_selector "img[class='canonical-image'][src='#{download_path(presenter, file: 'thumbnail')}']"

    # Action buttons
    expect(rendered).to have_selector "a[title=\"Edit My File\"][href='#{edit_polymorphic_path([:curation_concerns, presenter])}']", text: 'Edit'
    expect(rendered).to have_selector "a[title=\"Rollback to previous version\"][href='#{versions_curation_concerns_generic_file_path(presenter)}']", text: 'Rollback'
    expect(rendered).to have_selector "a[title=\"Delete My File\"][data-method='delete'][href='#{polymorphic_path([:curation_concerns, presenter])}']", text: 'Delete'
    expect(rendered).to have_link('Download')
    expect(rendered).to have_selector "a[title='Download \"My File\"'][href='#{download_path(presenter)}']", text: 'Download'
  end
end
