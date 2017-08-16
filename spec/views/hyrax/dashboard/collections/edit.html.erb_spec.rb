RSpec.describe 'hyrax/dashboard/collections/edit.html.erb', type: :view do
  let(:collection) { stub_model(Collection, id: 'xyz123z4', title: ["Make Collections Great Again"]) }
  let(:form) { Hyrax::Forms::CollectionForm.new(collection, double, double) }
  let(:solr_response) { double(response: { 'numFound' => 0 }) }

  before do
    allow(view).to receive(:has_collection_search_parameters?).and_return(false)
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    assign(:collection, collection)
    assign(:form, form)
    assign(:response, solr_response)
    stub_template 'hyrax/collections/_search_form.html.erb' => 'search form'
    stub_template 'hyrax/my/_did_you_mean.html.erb' => 'did you mean'
    stub_template 'hyrax/collections/_sort_and_per_page.html.erb' => 'sort and per page'
    stub_template '_document_list.html.erb' => 'document list'
    stub_template 'hyrax/collections/_paginate.html.erb' => 'paginate'
    stub_template '_form.html.erb' => 'form'

    render
  end

  it 'displays the page' do
    expect(rendered).to have_content 'Actions'
    expect(rendered).to have_link 'Add works'
  end
end
