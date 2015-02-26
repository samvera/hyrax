require 'spec_helper'

describe 'catalog/_sort_and_per_page.html.erb', :type => :view do
  before do
    allow(controller).to receive(:current_user).and_return(stub_model(User))
    allow_any_instance_of(Ability).to receive(:can?).and_return(true)
    @resp = ["a","b","c"]
    assign(:response, @resp )
    allow(@resp).to receive(:total_count).and_return(20)
    allow(@resp).to receive(:limit_value).and_return(3)
    allow(@resp).to receive(:rows).and_return(3)
    allow(@resp).to receive(:offset_value).and_return(3)
    allow(@resp).to receive(:current_page).and_return(2)
    allow(@resp).to receive(:total_pages).and_return(7)
    allow(view).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
  end

  it 'appears on page without error' do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_selector('span.page_entries', count: 1)
    expect(rendered).to include("<strong>4</strong> - <strong>6</strong> of <strong>20</strong>")
  end
  
  it 'displays the relevance option for sorting' do
    render
    page = Capybara::Node::Simple.new(rendered)
    expect(rendered).to include("<li><a href=\"/catalog?sort=score+desc%2C+date_uploaded_dtsi+desc\">relevance</a></li>")
  end

end
