require 'spec_helper'

RSpec.describe 'sufia/admin/admin_sets/_form.html.erb', type: :view do
  let(:admin_set) { create(:admin_set) }
  let!(:workflow) { Sipity::Workflow.create!(name: "default", label: "default") }
  let!(:permission_template) { Sufia::PermissionTemplate.find_or_create_by(admin_set_id: admin_set.id, workflow_name: 'default') }
  before do
    @form = Sufia::Forms::AdminSetForm.new(admin_set, permission_template)
    render
  end
  it "has the edit form" do
    expect(rendered).to have_select('admin_set[workflow_name]', selected: 'default')
  end
  it "has the metadata fields" do
    expect(rendered).to have_selector('input[type=text][name="admin_set[title]"]')
    expect(rendered).to have_selector('textarea[name="admin_set[description]"]')
  end
end
