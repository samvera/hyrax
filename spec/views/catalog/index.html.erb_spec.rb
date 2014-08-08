require 'spec_helper'

describe 'catalog/index.html.erb' do
  before do
    allow(view).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
    stub_template 'catalog/_search_sidebar.html.erb' => ''
    stub_template 'catalog/_search_header.html.erb' => ''
    allow(view).to receive(:render_opensearch_response_metadata).and_return('')
    allow(view).to receive(:render_grouped_response?).and_return(false)
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:current_search_session).and_return(nil)
    allow(view).to receive(:document_counter_with_offset).and_return(5)
    params[:view] = 'gallery'

    resp = []
    assign(:response, resp )
    allow(resp).to receive(:total_pages).and_return(1)
    allow(resp).to receive(:current_page).and_return(1)
    allow(resp).to receive(:limit_value).and_return(10)
    allow(resp).to receive(:empty?).and_return(false)

    @collection = Collection.new(pid: 'sufia:foo', title: 'collection1')
    doc = SolrDocument.new(@collection.to_solr.merge('has_model_ssim' => [Collection.to_class_uri]))
    assign(:document_list, [doc])
  end



  it 'appears on page without error' do
    render
    expect(rendered).to include(@collection.title)
    page = Capybara::Node::Simple.new(rendered)
    expect(page).to have_selector("span.glyphicon.glyphicon-th.collection-icon-search")
  end

end
