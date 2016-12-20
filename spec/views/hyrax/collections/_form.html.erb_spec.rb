describe 'hyrax/collections/_form.html.erb', type: :view do
  let(:collection) { build(:collection) }
  let(:collection_form) { Hyrax::Forms::CollectionForm.new(collection) }

  before do
    controller.request.path_parameters[:id] = 'j12345'
    assign(:form, collection_form)
    assign(:collection, collection)
    # Stub route because view specs don't handle engine routes
    allow(view).to receive(:collections_path).and_return("/collections")
    render
  end

  it "draws the metadata fields for collection" do
    expect(rendered).to have_selector("input#collection_title")
    expect(rendered).to have_selector("span.required-tag", text: "required")
    expect(rendered).not_to have_selector("div#additional_title.multi_value")
    expect(rendered).to have_selector("input#collection_creator.multi_value")
    expect(rendered).to have_selector("textarea#collection_description")
    expect(rendered).to have_selector("input#collection_contributor")
    expect(rendered).to have_selector("input#collection_keyword")
    expect(rendered).to have_selector("input#collection_subject")
    expect(rendered).to have_selector("input#collection_publisher")
    expect(rendered).to have_selector("input#collection_date_created")
    expect(rendered).to have_selector("input#collection_language")
    expect(rendered).to have_selector("input#collection_identifier")
    expect(rendered).to have_selector("input#collection_based_near")
    expect(rendered).to have_selector("input#collection_related_url")
    expect(rendered).to have_selector("select#collection_rights")
    expect(rendered).to have_selector("select#collection_resource_type")
    expect(rendered).not_to have_selector("input#collection_visibility")
  end
end
