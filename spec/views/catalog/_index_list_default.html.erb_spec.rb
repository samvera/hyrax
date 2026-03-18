# frozen_string_literal: true
RSpec.describe 'catalog/_index_list_default', type: :view do
  let(:attributes) do
    { 'creator_tesim' => ['Test creator_tesim'],
      'depositor_tesim' => ['Test depositor_tesim'],
      'proxy_depositor_ssim' => ['Test proxy_depositor_ssim'],
      'description_tesim' => ['Test description_tesim'],
      'date_uploaded_dtsi' => Time.zone.today.to_s,
      'date_modified_dtsi' => Time.zone.today.to_s,
      'embargo_release_date_dtsi' => Time.zone.today.to_s,
      'lease_expiration_date_dtsi' => Time.zone.today.to_s,
      'has_model_ssim' => 'GenericWork' }
  end
  let(:document) { SolrDocument.new(attributes) }

  before do
    # Set up proper view context and mocks without affecting global state
    allow(view).to receive(:current_ability).and_return(double('Ability'))

    # Blacklight 7.41+ calls context.method(:render_optionally?) on the view instance.
    # Define it as a singleton method so it's found regardless of which instance is used.
    view.define_singleton_method(:render_optionally?) { true }
    controller.class.define_method(:render_optionally?) { true }

    # Mock the facet link rendering in a more targeted way
    allow_any_instance_of(Blacklight::Rendering::LinkToFacet)
      .to receive(:search_path).and_return('http://example.com')
  end

  it "displays metadata" do
    render 'catalog/index_list_default', document: document

    expect(rendered).not_to include 'Title:'
    expect(rendered).to include 'Creator:'
    expect(rendered).to include 'Test creator_tesim'
    expect(rendered).to include 'Description:'
    expect(rendered).to include 'Test description_tesim'
    expect(rendered).to include 'Date Uploaded:'
    expect(rendered).to include 'Date Modified:'
    expect(rendered).to include 'Depositor:'
    expect(rendered).to include 'Test proxy_depositor_ssim'
    expect(rendered).to include 'Owner:'
    expect(rendered).to include 'Test depositor_tesim'
    expect(rendered).to include 'Embargo release date:'
    expect(rendered).to include 'Lease expiration date:'
  end
end
