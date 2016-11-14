require 'spec_helper'

RSpec.describe 'sufia/admin/admin_sets/_form_participants.html.erb', type: :view do
  let(:admin_set) { create(:admin_set) }
  let(:permission_template) { Sufia::PermissionTemplate.find_or_create_by(admin_set_id: admin_set.id) }
  before do
    @form = Sufia::Forms::AdminSetForm.new(admin_set, permission_template)
    render
  end
  it "has the required selectors" do
    expect(rendered).to have_selector('#participants #user-participants-form input[type=text]')
  end
end
