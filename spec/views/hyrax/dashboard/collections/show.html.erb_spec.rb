RSpec.describe 'hyrax/dashboard/collections/show.html.erb', type: :view do
  let(:document) do
    SolrDocument.new(id: 'xyz123z4',
                     'title_tesim' => ['Make Collections Great Again'],
                     'rights_tesim' => ["http://creativecommons.org/licenses/by-sa/3.0/us/"])
  end
  let(:ability) { double }
  let(:presenter) { Hyrax::CollectionPresenter.new(document, ability) }

  before do
    allow(document).to receive(:hydra_model).and_return(::Collection)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow(view).to receive(:can?).with(:edit, document).and_return(true)
    allow(view).to receive(:can?).with(:destroy, document).and_return(true)
    allow(presenter).to receive(:total_items).and_return(0)
    assign(:presenter, presenter)

    # Stub route because view specs don't handle engine routes
    allow(view).to receive(:edit_dashboard_collection_path).and_return("/dashboard/collection/123/edit")
    allow(view).to receive(:collection_path).and_return("/dashboard/collection/123")

    stub_template 'hyrax/collections/_search_form.html.erb' => 'search form'
    stub_template 'hyrax/dashboard/collections/_sort_and_per_page.html.erb' => 'sort and per page'
    stub_template '_document_list.html.erb' => 'document list'
    stub_template 'hyrax/collections/_paginate.html.erb' => 'paginate'
    stub_template 'hyrax/collections/_media_display.html.erb' => '<span class="fa fa-cubes collection-icon-search"></span>'
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
