describe 'my/_index_partials/_list_collections.html.erb', type: :view do
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
  let(:config) { My::WorksController.blacklight_config }
  let(:blacklight_configuration_context) do
    Blacklight::Configuration::Context.new(controller)
  end

  before do
    allow(view).to receive(:current_user).and_return(stub_model(User))
    allow(view).to receive(:blacklight_config) { config }
    allow(view).to receive(:blacklight_configuration_context).and_return(blacklight_configuration_context)
    allow(doc).to receive(:to_model).and_return(stub_model(Collection, id: id))
    view.lookup_context.prefixes.push 'my'

    render 'my/_index_partials/list_collections', document: doc
  end

  it 'the line item displays the work and its actions' do
    expect(rendered).to have_selector("tr#document_#{id}")
    expect(rendered).to have_link 'Collection Title', href: collection_path(id)
    expect(rendered).to have_link 'Edit Collection', href: edit_collection_path(id)
    expect(rendered).to have_link 'Delete Collection', href: collection_path(id)
    expect(rendered).to have_css 'a.visibility-link', text: 'Private'
    expect(rendered).to have_selector '.expanded-details dd', text: 'Collection Description'
  end
end
