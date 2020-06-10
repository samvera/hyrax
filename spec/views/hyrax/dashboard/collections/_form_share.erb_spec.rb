# frozen_string_literal: true
RSpec.describe 'hyrax/dashboard/collections/_form_share.html.erb', type: :view do
  let(:template) { stub_model(Hyrax::PermissionTemplate) }
  let(:pt_form) do
    instance_double(Hyrax::Forms::PermissionTemplateForm,
                    model_name: template.model_name,
                    to_key: template.to_key,
                    access_grants: template.access_grants)
  end
  let(:collection) { stub_model(Collection, share_applies_to_new_works?: false) }

  before do
    assign(:collection, collection)
    @form = instance_double(Hyrax::Forms::CollectionForm,
                            to_model: collection,
                            permission_template: pt_form,
                            id: '1234xyz')
    render
  end
  it "has the required selectors" do
    expect(rendered).to have_selector('#participants #user-participants-form input[type=text]')
  end
end
