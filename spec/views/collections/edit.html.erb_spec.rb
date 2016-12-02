describe 'collections/edit.html.erb', type: :view do
  let(:collection) { stub_model(Collection, id: 'xyz123z4', title: ["Make Collections Great Again"]) }
  let(:form) { Sufia::Forms::CollectionForm.new(collection) }
  let(:solr_response) { double(response: { 'numFound' => 0 }) }

  before do
    allow(view).to receive(:has_collection_search_parameters?).and_return(false)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign(:collection, collection)
    assign(:form, form)
    assign(:response, solr_response)
    stub_template 'collections/_search_form.html.erb' => 'search form'
    stub_template 'sufia/my/_did_you_mean.html.erb' => 'did you mean'
    stub_template 'collections/_sort_and_per_page.html.erb' => 'sort and per page'
    stub_template 'collections/_document_list.html.erb' => 'document list'
    stub_template 'collections/_paginate.html.erb' => 'paginate'
    render
  end

  it 'displays the page' do
    expect(rendered).to have_content 'Actions'
    expect(rendered).to have_link 'Add works'
  end
end
