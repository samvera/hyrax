RSpec.describe 'hyrax/collections/show.html.erb', type: :view do
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
    allow(controller).to receive(:banner_file).with("xyz123z4").and_return("banner.gif")
    allow(controller).to receive(:logo_record).with("xyz123z4").and_return([{ linkurl: "logo link url", alttext: "logo alt text", file_location: "logo.gif" }])
    assign(:presenter, presenter)

    # Stub route because view specs don't handle engine routes
    allow(view).to receive(:collection_path).and_return("/collection/123")

    stub_template '_search_form.html.erb' => 'search form'
    stub_template 'hyrax/collections/_sort_and_per_page.html.erb' => 'sort and per page'
    stub_template 'hyrax/collections/_document_list.html.erb' => 'document list'
    stub_template 'hyrax/collections/_paginate.html.erb' => 'paginate'
    stub_template 'hyrax/collections/_media_display.html.erb' => '<span class="fa fa-cubes collection-icon-search"></span>'
    render
  end

  it 'draws the page' do
    expect(rendered).to match '<span class="fa fa-cubes collection-icon-search"></span>'
  end
end
