RSpec.describe 'hyrax/my/collections/_list_collections.html.erb', type: :view do
  let(:id) { "3197z511f" }
  let(:attributes) do
    {
      id: id,
      "has_model_ssim" => ["Collection"],
      "title_tesim" => ["Collection Title"],
      "description_tesim" => ["Collection Description"]
    }
  end

  let(:doc) { SolrDocument.new(attributes) }
  let(:collection) { mock_model(Collection) }

  before do
    allow(view).to receive(:current_user).and_return(stub_model(User))
    allow(doc).to receive(:to_model).and_return(stub_model(Collection, id: id))
    view.lookup_context.prefixes.push 'hyrax/my'

    render 'hyrax/my/collections/list_collections', document: doc
  end

  it 'the line item displays the work and its actions' do
    expect(rendered).to have_selector("tr#document_#{id}")
    expect(rendered).to have_link 'Collection Title', href: hyrax.collection_path(id)
    expect(rendered).to have_link 'Edit Collection', href: hyrax.edit_collection_path(id)
    expect(rendered).to have_link 'Delete Collection', href: hyrax.collection_path(id)
    expect(rendered).to have_css 'a.visibility-link', text: 'Private'
    expect(rendered).to have_selector '.expanded-details dd', text: 'Collection Description'
    expect(rendered).not_to include '<span class="fa fa-cubes collection-icon-small pull-left"></span></a>'
  end
end
