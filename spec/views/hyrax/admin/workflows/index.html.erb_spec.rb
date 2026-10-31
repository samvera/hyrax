# frozen_string_literal: true
RSpec.describe "hyrax/admin/workflows/index.html.erb", type: :view do
  let(:response) { Hyrax::Admin::WorkflowsController::WorkflowResponse.new([], 0, 1, 10, true) }

  before do
    assign(:response, response)
    allow(view).to receive(:search_state).and_return(Blacklight::SearchState.new({}, CatalogController.blacklight_config))
    stub_template 'hyrax/my/_results_pagination.html.erb' => ''
    render
  end

  it "offers the number of results per page as a working select, not escaped markup" do
    expect(rendered).to have_select('per_page', options: Hyrax.config.range_for_number_of_results_to_display_per_page.map(&:to_s))
    expect(rendered).to have_css('label', text: /Show\s+.*\s+per page/m)
    expect(rendered).not_to include('&lt;select')
    expect(rendered).not_to include(') per page')
  end
end
