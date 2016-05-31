require 'spec_helper'

describe 'curation_concerns/base/_member.html.erb' do
  let(:solr_document) { SolrDocument.new(id: '999',
                                         has_model_ssim: ['FileSet'],
                                         active_fedora_model_ssi: 'FileSet',
                                         thumbnail_path_ss: '/downloads/999?file=thumbnail',
                                         representative_tesim: ["999"],
                                         title_tesim: ["My File"]) }

  # Ability is checked in FileSetPresenter#link_name
  let(:ability) { double(can?: true) }
  let(:presenter) { CurationConcerns::FileSetPresenter.new(solr_document, ability) }
  let(:blacklight_configuration_context) do
    Blacklight::Configuration::Context.new(controller)
  end

  before do
    assign(:presenter, presenter)
    allow(view).to receive(:blacklight_configuration_context).and_return(blacklight_configuration_context)
    allow(view).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
    allow(view).to receive(:current_search_session).and_return nil
    allow(view).to receive(:search_session).and_return({})
    # abilities called in _actions.html.erb
    allow(view).to receive(:can?).with(:read, kind_of(String)).and_return(true)
    allow(view).to receive(:can?).with(:edit, kind_of(String)).and_return(true)
    allow(view).to receive(:can?).with(:destroy, String).and_return(true)
    allow(view).to receive(:contextual_path).with(anything, anything) do |x, y|
      CurationConcerns::ContextualPath.new(x, y).show
    end
    render 'curation_concerns/base/member.html.erb', member: presenter
  end

  it 'renders the view' do
    # A thumbnail
    expect(rendered).to have_selector ".thumbnail img[src='#{download_path(presenter, file: 'thumbnail')}']"

    # Action buttons
    expect(rendered).to have_selector "a[title=\"Edit My File\"][href='#{edit_polymorphic_path(presenter)}']", text: 'Edit'
    expect(rendered).to have_selector "a[title=\"Rollback to previous version\"][href='#{versions_curation_concerns_file_set_path(presenter)}']", text: 'Rollback'
    expect(rendered).to have_selector "a[title=\"Delete My File\"][data-method='delete'][href='#{polymorphic_path(presenter)}']", text: 'Delete'
    expect(rendered).to have_link('Download')
    expect(rendered).to have_selector "a[title='Download \"My File\"'][href='#{download_path(presenter)}']", text: 'Download'
  end
end
