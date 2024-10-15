# frozen_string_literal: true
RSpec.describe 'hyrax/base/_member.html.erb' do
  let(:work_solr_document) do
    SolrDocument.new(id: '900', title_tesim: ['My Title'])
  end
  let(:solr_document) do
    SolrDocument.new(id: '999',
                     has_model_ssim: ['FileSet'],
                     active_fedora_model_ssi: 'FileSet',
                     thumbnail_path_ss: '/downloads/999?file=thumbnail',
                     representative_tesim: ["999"],
                     title_tesim: ["My File"])
  end

  # Ability is checked in FileSetPresenter#link_name
  let(:ability) { double(can?: true) }
  let(:presenter) { Hyrax::FileSetPresenter.new(solr_document, ability) }
  let(:parent_presenter) { Hyrax::WorkShowPresenter.new(work_solr_document, ability) }

  before do
    allow(controller).to receive(:current_ability).and_return(ability)
    assign(:presenter, presenter)
    assign(:parent_presenter, parent_presenter)
    allow(presenter).to receive(:parent_presenter).and_return parent_presenter
    allow(presenter).to receive(:parent).and_return parent_presenter
    allow(view).to receive(:session_tracking_params).and_return({})
    # abilities called in _actions.html.erb
    allow(view).to receive(:can?).with(:download, kind_of(String)).and_return(true)
    allow(view).to receive(:can?).with(:edit, kind_of(String)).and_return(true)
    allow(view).to receive(:can?).with(:destroy, String).and_return(true)
    allow(view).to receive(:contextual_path).with(anything, anything) do |x, y|
      Hyrax::ContextualPath.new(x, y).show
    end
    render 'hyrax/base/member', member: presenter
  end

  it 'checks the :download ability' do
    expect(view).to have_received(:can?).with(:download, kind_of(String)).at_least(1).times
  end

  it 'renders the view' do
    # A thumbnail
    expect(rendered).to have_selector ".thumbnail img[src='#{hyrax.download_path(presenter, file: 'thumbnail')}']"

    # Action buttons
    expect(rendered).to have_selector "a[title=\"Edit My File\"][href='#{edit_polymorphic_path(presenter)}']", text: 'Edit'
    expect(rendered).to have_selector "a[title=\"Delete My File\"][data-method='delete'][href='#{polymorphic_path(presenter)}']", text: 'Delete'
    expect(rendered).to have_link('Download')
    expect(rendered).to have_selector "a[title='Download My File'][href='#{hyrax.download_path(presenter)}']", text: 'Download'
  end
end
