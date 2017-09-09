RSpec.describe 'hyrax/my/collections/_list_collections.html.erb', type: :view do
  let(:id) { "3197z511f" }
  let(:modified_date) {  DateTime.new(2014, 1, 1).iso8601 }

  let(:attributes) do
    {
      id: id,
      "has_model_ssim" => ["Collection"],
      "title_tesim" => ["Collection Title"],
      "description_tesim" => ["Collection Description"],
      "system_modified_dtsi" => modified_date
    }
  end

  let(:doc) { SolrDocument.new(attributes) }
  let(:collection) { mock_model(Collection) }
  let(:collection_presenter) { Hyrax::CollectionPresenter.new(doc, nil, nil) }

  before do
    allow(view).to receive(:current_user).and_return(stub_model(User))
    allow(doc).to receive(:to_model).and_return(stub_model(Collection, id: id))
    allow(collection_presenter).to receive(:collection_type_badge).and_return("User Collection")
    view.lookup_context.prefixes.push 'hyrax/my'

    render 'hyrax/my/collections/list_collections', collection_presenter: collection_presenter
  end

  xit 'the line item displays the work and its actions' do
    expect(rendered).to have_selector("tr#document_#{id}")
    expect(rendered).to have_link 'Collection Title', href: hyrax.dashboard_collection_path(id)
    expect(rendered).to have_link 'Edit collection', href: hyrax.edit_dashboard_collection_path(id)
    expect(rendered).to have_link 'Delete collection', href: hyrax.dashboard_collection_path(id)
    expect(rendered).to have_css 'a.visibility-link', text: 'Private'
    expect(rendered).to have_css '.collection_type', text: 'User Collection'
    expect(rendered).to have_selector '.expanded-details', text: 'Collection Description'
    expect(rendered).not_to include '<span class="fa fa-cubes collection-icon-small"></span></a>'
    expect(rendered).to include Date.parse(modified_date).to_formatted_s(:standard)
  end
end
