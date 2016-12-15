require 'spec_helper'

describe 'hyrax/base/show.html.erb', type: :view do
  let(:solr_document) do
    SolrDocument.new(id: '999',
                     date_modified_dtsi: '2011-04-01',
                     has_model_ssim: ['GenericWork'])
  end
  let(:ability) { double }
  let(:presenter) do
    Hyrax::WorkShowPresenter.new(solr_document, ability)
  end
  let(:page) { Capybara::Node::Simple.new(rendered) }
  before do
    stub_template 'hyrax/base/_metadata.html.erb' => ''
    stub_template 'hyrax/base/_relationships.html.erb' => ''
    stub_template 'hyrax/base/_show_actions.html.erb' => ''
    stub_template 'hyrax/base/_representative_media.html.erb' => ''
    stub_template 'hyrax/base/_social_media.html.erb' => ''
    stub_template 'hyrax/base/_citations.html.erb' => ''
    stub_template 'hyrax/base/_items.html.erb' => ''
    assign(:presenter, presenter)
    render
  end

  it 'shows last saved' do
    expect(page).to have_content 'Last modified: 04/01/2011'
  end
end
