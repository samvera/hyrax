require 'spec_helper'

describe 'catalog/_index_list_default' do
  let(:attributes) do
    { 'creator_tesim' => ['Justin', 'Joe'],
      'depositor_tesim' => ['jcoyne@justincoyne.com'],
      'proxy_depositor_ssim' => ['atz@stanford.edu'],
      'description_tesim' => ['This links to http://example.com/ What about that?'],
      'date_uploaded_dtsi' => '2013-03-14T00:00:00Z' }
  end
  let(:document) { SolrDocument.new(attributes) }
  let(:blacklight_configuration_context) do
    Blacklight::Configuration::Context.new(controller)
  end
  let(:joe) { stub_model(User, email: 'atz@stanford.edu') }
  let(:justin) { stub_model(User, email: 'jcoyne@justincoyne.com') }

  before do
    allow(User).to receive(:find_by_user_key).and_return(joe, justin)
    allow(view).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
    allow(view).to receive(:blacklight_configuration_context).and_return(blacklight_configuration_context)
    render 'catalog/index_list_default', document: document
  end

  it "displays metadata" do
    expect(rendered).not_to include 'Title:'
    expect(rendered).to include '<span class="attribute-label h4">Creator:</span>'
    expect(rendered).to include '<span itemprop="creator">Justin</span> and <span itemprop="creator">Joe</span>'
    expect(rendered).to include '<span class="attribute-label h4">Description:</span>'
    expect(rendered).to include '<span itemprop="description">This links to <a href="http://example.com/"><span class="glyphicon glyphicon-new-window"></span> http://example.com/</a> What about that?</span>'
    expect(rendered).to include '<span class="attribute-label h4">Date Uploaded:</span>'
    expect(rendered).to include '<span itemprop="datePublished">03/14/2013</span>'
    expect(rendered).to include '<span class="attribute-label h4">Depositor:</span>'
    expect(rendered).to include '<a href="/users/atz@stanford-dot-edu">atz@stanford.edu</a>'
    expect(rendered).to include '<span class="attribute-label h4">Owner:</span>'
    expect(rendered).to include '<a href="/users/jcoyne@justincoyne-dot-com">jcoyne@justincoyne.com</a>'
  end
end
