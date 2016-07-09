
describe 'catalog/_index_list_default', type: :view do
  let(:attributes) do
    { 'creator_tesim'        => [''],
      'depositor_tesim'      => [''],
      'proxy_depositor_ssim' => [''],
      'description_tesim'    => [''],
      'date_uploaded_dtsi'   => 'a date',
      'rights_tesim'         => [''] }
  end
  let(:document) { SolrDocument.new(attributes) }
  let(:blacklight_configuration_context) do
    Blacklight::Configuration::Context.new(controller)
  end
  let(:presenter) { double }
  before do
    allow(view).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
    allow(view).to receive(:blacklight_configuration_context).and_return(blacklight_configuration_context)
    allow(view).to receive(:index_presenter).and_return(presenter)
    allow(presenter).to receive(:field_value) { |field| "Test #{field}" }
    render 'catalog/index_list_default', document: document
  end

  it "displays metadata" do
    expect(rendered).not_to include 'Title:'
    expect(rendered).to include '<span class="attribute-label h4">Creator:</span>'
    expect(rendered).to include 'Test creator_tesim'
    expect(rendered).to include '<span class="attribute-label h4">Description:</span>'
    expect(rendered).to include 'Test description_tesim'
    expect(rendered).to include '<span class="attribute-label h4">Date Uploaded:</span>'
    expect(rendered).to include 'Test date_uploaded_dtsi'
    expect(rendered).to include '<span class="attribute-label h4">Depositor:</span>'
    expect(rendered).to include 'Test proxy_depositor_ssim'
    expect(rendered).to include '<span class="attribute-label h4">Owner:</span>'
    expect(rendered).to include 'Test depositor_tesim'
    expect(rendered).to include '<span class="attribute-label h4">Rights:</span>'
    expect(rendered).to include 'Test rights_tesim'
  end
end
