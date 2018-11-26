RSpec.describe 'catalog/_index_list_default', type: :view do
  let(:attributes) do
    { 'creator_tesim'        => [''],
      'depositor_tesim'      => [''],
      'proxy_depositor_ssim' => [''],
      'description_tesim'    => [''],
      'date_uploaded_dtsi'   => 'a date',
      'date_modified_dtsi'   => 'a date',
      'rights_statement_tesim' => [''],
      'embargo_release_date_dtsi' => 'a date',
      'lease_expiration_date_dtsi' => 'a date',
      'has_model_ssim' => 'GenericWork' }
  end
  let(:document) { SolrDocument.new(attributes) }
  let(:presenter) { double }

  before do
    allow(view).to receive(:index_presenter).and_return(presenter)
    allow(presenter).to receive(:field_value) { |field| "Test #{field.field}" }
    render 'catalog/index_list_default', document: document
  end

  it "displays metadata" do
    expect(rendered).not_to include 'Title:'
    expect(rendered).to include 'Creator:'
    expect(rendered).to include 'Test creator_tesim'
    expect(rendered).to include 'Description:'
    expect(rendered).to include 'Test description_tesim'
    expect(rendered).to include 'Date Uploaded:'
    expect(rendered).to include 'Test date_uploaded_dtsi'
    expect(rendered).to include 'Date Modified:'
    expect(rendered).to include 'Test date_modified_dtsi'
    expect(rendered).to include 'Depositor:'
    expect(rendered).to include 'Test proxy_depositor_ssim'
    expect(rendered).to include 'Owner:'
    expect(rendered).to include 'Test depositor_tesim'
    expect(rendered).to include 'Rights Statement:'
    expect(rendered).to include 'Test rights_statement_tesim'
    expect(rendered).to include 'Embargo release date:'
    expect(rendered).to include 'Test embargo_release_date_dtsi'
    expect(rendered).to include 'Lease expiration date:'
    expect(rendered).to include 'Test lease_expiration_date_dtsi'
  end
end
