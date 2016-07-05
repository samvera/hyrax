require 'spec_helper'

describe 'catalog/index.html.erb' do
  let(:collection) { stub_model(Collection, title: ['collection1'], id: 'abc123') }
  let(:doc) { SolrDocument.new(collection.to_solr) }
  let(:search_state) { double('SearchState', to_h: {}) }
  let(:blacklight_configuration_context) do
    Blacklight::Configuration::Context.new(controller)
  end

  before do
    view.extend CurationConcerns::CollectionsHelper
    view.extend CurationConcerns::CatalogHelper

    allow(controller).to receive(:action_name).and_return('index')
    allow(view).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
    allow(view).to receive(:blacklight_configuration_context).and_return(blacklight_configuration_context)
    stub_template 'catalog/_search_sidebar.html.erb' => ''
    stub_template 'catalog/_search_header.html.erb' => ''
    allow(view).to receive(:render_opensearch_response_metadata).and_return('')
    allow(view).to receive(:render_grouped_response?).and_return(false)
    allow(view).to receive(:search_session).and_return({})
    allow(view).to receive(:current_search_session).and_return(nil)
    allow(view).to receive(:document_counter_with_offset).and_return(5)
    allow(view).to receive(:type_tab).and_return("TYPE")
    allow(view).to receive(:search_state).and_return(search_state)

    params[:view] = 'gallery'

    resp = []
    assign(:response, resp)
    allow(resp).to receive(:total_pages).and_return(1)
    allow(resp).to receive(:current_page).and_return(1)
    allow(resp).to receive(:limit_value).and_return(10)
    allow(resp).to receive(:empty?).and_return(false)

    # This stubs out the SolrDocument#to_model
    allow(ActiveFedora::Base).to receive(:load_instance_from_solr).with('abc123', doc).and_return(collection)

    assign(:document_list, [doc])
  end

  context 'when user does not have permissions' do
    before { allow(view).to receive(:can?).and_return(false) }
    it 'appears on page without error' do
      render
      page = Capybara::Node::Simple.new(rendered)
      expect(page).to have_link 'collection1'
      expect(page).to have_content 'List of items deposited'
    end
  end

  context 'when user has all the permissions' do
    before { allow(view).to receive(:can?).and_return(true) }

    it 'appears on page without error' do
      render
      page = Capybara::Node::Simple.new(rendered)
      expect(page).to have_link 'collection1'
      expect(page).to have_content 'List of items deposited'
    end
  end
end
