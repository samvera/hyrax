require 'spec_helper'

describe 'curation_concerns/base/_attribute_rows.html.erb', type: :view do
  let(:url) { "http://example.com" }
  let(:ability) { double }
  let(:work) { stub_model(GenericWork, related_url: [url]) }
  let(:solr_document) { SolrDocument.new(work.to_solr) }
  let(:presenter) { Sufia::WorkShowPresenter.new(solr_document, ability) }

  let(:page) do
    render 'curation_concerns/base/attribute_rows', presenter: presenter
    Capybara::Node::Simple.new(rendered)
  end

  it 'shows external link with icon for related url field' do
    expect(page).to have_selector '.glyphicon-new-window'
    expect(page).to have_link(url)
  end
end
