require 'spec_helper'

RSpec.describe 'sufia/admin/admin_sets/_form_metadata.html.erb', type: :view do
  let(:admin_set) { create(:admin_set) }
  let(:permission_template) { Sufia::PermissionTemplate.find_or_create_by(admin_set_id: admin_set.id) }
  before do
    @form = Sufia::Forms::AdminSetForm.new(admin_set, permission_template)
    render 'form'
  end
  it "has the metadata fields" do
    expect(rendered).to have_selector('input[type=text][name="admin_set[title]"]')
    expect(rendered).to have_selector('textarea[name="admin_set[description]"]')
  end
end
