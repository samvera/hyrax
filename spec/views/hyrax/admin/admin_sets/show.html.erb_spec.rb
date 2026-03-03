# frozen_string_literal: true
RSpec.describe "hyrax/admin/admin_sets/show.html.erb", type: :view do
  let(:solr_document) { SolrDocument.new }
  let(:ability) { instance_double("Ability") }
  let(:presenter) { Hyrax::AdminSetPresenter.new(solr_document, ability) }

  before do
    stub_template 'hyrax/admin/admin_sets/_collection_description.html.erb' => ''
    stub_template 'hyrax/admin/admin_sets/_show_actions.html.erb' => ''
    stub_template 'hyrax/admin/admin_sets/_show_descriptions.html.erb' => ''
    stub_template 'hyrax/admin/admin_sets/_sort_and_per_page.html.erb' => 'sort and per page'
    stub_template 'hyrax/admin/admin_sets/_document_list.html.erb' => 'document list'
    stub_template 'hyrax/admin/admin_sets/_paginate.html.erb' => 'paginate'

    assign(:member_docs, [])
    assign(:presenter, presenter)
    render
  end

  it "displays a disabled delete button" do
    expect(rendered).to have_selector('div.admin-set')
  end
end
