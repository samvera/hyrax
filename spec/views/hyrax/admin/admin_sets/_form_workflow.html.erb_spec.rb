require 'spec_helper'

RSpec.describe 'hyrax/admin/admin_sets/_form_workflow.html.erb', type: :view do
  let(:template) { stub_model(Hyrax::PermissionTemplate) }
  let(:workflow) { stub_model(Sipity::Workflow, name: "my_name", description: "random workflow", label: "my label") }
  let(:pt_form) do
    instance_double(Hyrax::Forms::PermissionTemplateForm,
                    model_name: template.model_name,
                    persisted?: template.persisted?,
                    to_key: template.to_key,
                    workflows: [workflow],
                    workflow_id: workflow.id)
  end
  before do
    @form = instance_double(Hyrax::Forms::AdminSetForm,
                            to_model: stub_model(AdminSet),
                            permission_template: pt_form)
    render
  end
  it "has the radio button for workflow" do
    expect(rendered).to have_selector("#workflow label[for=\"permission_template_workflow_id_#{workflow.id}\"] input[type=radio][name=\"permission_template[workflow_id]\"][value=\"#{workflow.id}\"]")
  end
end
