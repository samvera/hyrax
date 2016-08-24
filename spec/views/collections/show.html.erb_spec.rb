describe 'collections/show.html.erb', type: :view do
  let(:document) { SolrDocument.new(id: 'xyz123z4',
                                    'title_tesim' => ['Make Collections Great Again']) }
  let(:ability) { double }
  let(:presenter) { Sufia::CollectionPresenter.new(document, ability) }
  let(:blacklight_config) { CatalogController.blacklight_config }
  let(:blacklight_configuration_context) do
    Blacklight::Configuration::Context.new(controller)
  end

  before do
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:blacklight_configuration_context).and_return(blacklight_configuration_context)
    allow(document).to receive(:hydra_model).and_return(::Collection)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(view).to receive(:can?).with(:edit, document).and_return(true)
    allow(view).to receive(:can?).with(:destroy, document).and_return(true)
    assign(:presenter, presenter)
    stub_template '_search_form.html.erb' => 'search form'
    stub_template 'collections/_sort_and_per_page.html.erb' => 'sort and per page'
    stub_template 'collections/_document_list.html.erb' => 'document list'
    stub_template 'collections/_paginate.html.erb' => 'paginate'
    stub_template 'collections/_media_display.html.erb' => '<span class="fa fa-cubes collection-icon-search"></span>'
    render
  end

  it 'draws the page' do
    expect(rendered).to have_selector 'h2', text: 'Actions'
    expect(rendered).to have_link 'Edit'
    expect(rendered).to have_link 'Delete'
    expect(rendered).to have_link 'Add works'
    expect(rendered).to match '<span class="fa fa-cubes collection-icon-search"></span>'
  end
end
