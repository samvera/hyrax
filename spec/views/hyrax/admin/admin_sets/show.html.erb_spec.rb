# frozen_string_literal: true
RSpec.describe "hyrax/admin/admin_sets/show.html.erb", type: :view do
  let(:solr_document) { SolrDocument.new }
  let(:ability) { instance_double("Ability") }
  let(:presenter) { Hyrax::AdminSetPresenter.new(solr_document, ability) }

  before do
    stub_template '_collection_description.html.erb' => ''
    stub_template '_show_actions.erb' => ''
    stub_template '_show_descriptions.erb' => ''
    stub_template '_sort_and_per_page.html.erb' => 'sort and per page'
    stub_template '_document_list.html.erb' => 'document list'
    stub_template '_paginate.html.erb' => 'paginate'

    assign(:presenter, presenter)
    render
  end

  it "displays a disabled delete button" do
    expect(rendered).to have_selector('div.admin-set')
  end
end
