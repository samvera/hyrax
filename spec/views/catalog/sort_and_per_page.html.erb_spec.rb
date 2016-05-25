
describe 'catalog/_sort_and_per_page.html.erb', type: :view do
  let(:blacklight_configuration_context) do
    Blacklight::Configuration::Context.new(controller)
  end
  let(:search_state) { double('SearchState', to_h: {}, params_for_search: { sort: "score desc, system_create_dtsi desc" }) }
  before do
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow_any_instance_of(Ability).to receive(:can?).and_return(true)
    @resp = ["a", "b", "c"]
    assign(:response, @resp)
    allow(@resp).to receive(:total_count).and_return(20)
    allow(@resp).to receive(:limit_value).and_return(3)
    allow(@resp).to receive(:rows).and_return(3)
    allow(@resp).to receive(:offset_value).and_return(3)
    allow(@resp).to receive(:current_page).and_return(2)
    allow(@resp).to receive(:total_pages).and_return(7)
    allow(view).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
    allow(view).to receive(:blacklight_configuration_context).and_return(blacklight_configuration_context)
    allow(view).to receive(:search_state).and_return(search_state)
  end

  it 'appears on page without error' do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_selector('span.page_entries', count: 1)
    expect(rendered).to include("<strong>4</strong> - <strong>6</strong> of <strong>20</strong>")
  end

  it 'displays the relevance option for sorting' do
    render
    expect(rendered).to include("<li><a href=\"/catalog?sort=score+desc%2C+system_create_dtsi+desc\">relevance</a></li>")
  end
end
