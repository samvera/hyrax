# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_form_branding.html.erb', type: :view do
  let(:banner_info) { { file: "banner.gif" } }
  let(:logo_info) { [{ file: "logo.gif", alttext: "Logo alt text", linkurl: "http://abc.com" }] }

  let(:form_builder) { double("FormBuilder", object: form) }
  let(:form) do
    instance_double(Hyrax::Forms::CollectionForm,
                    banner_info: banner_info,
                    logo_info: logo_info)
  end

  before do
    assign(:form, form)
    render 'hyrax/dashboard/collections/form_branding', f: form_builder
  end

  it "displays branding information for a collection" do
    expect(rendered).to include('banner.gif')
    expect(rendered).to include('logo.gif')
    expect(rendered).to include('Logo alt text')
    expect(rendered).to include('http://abc.com')
  end
end
