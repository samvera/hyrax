# frozen_string_literal: true
RSpec.describe 'hyrax/admin/admin_sets/_form_participants.html.erb', type: :view do
  let(:template) { stub_model(Hyrax::PermissionTemplate) }
  let(:pt_form) do
    instance_double(Hyrax::Forms::PermissionTemplateForm,
                    model_name: template.model_name,
                    to_key: template.to_key,
                    access_grants: template.access_grants)
  end

  before do
    @form = instance_double(Hyrax::Forms::AdminSetForm,
                            to_model: stub_model(AdminSet),
                            permission_template: pt_form)
    render
  end
  it "has the required selectors" do
    expect(rendered).to have_selector('#participants #user-participants-form input[type=text]')
  end
end
