require 'spec_helper'

RSpec.describe 'hyrax/admin/admin_sets/_form_workflow.html.erb', type: :view do
  let(:admin_set) { create(:admin_set) }
  let(:permission_template) { Hyrax::PermissionTemplate.find_or_create_by(admin_set_id: admin_set.id) }
  before do
    create(:workflow, name: "my_name", description: "random workflow", label: "my label")
    @form = Hyrax::Forms::AdminSetForm.new(admin_set, permission_template)
    render
  end
  it "has the radio button for workflow" do
    expect(rendered).to have_selector('#workflow label[for="permission_template_workflow_name_my_name"] input[type=radio][name="permission_template[workflow_name]"][value="my_name"]')
  end
end
