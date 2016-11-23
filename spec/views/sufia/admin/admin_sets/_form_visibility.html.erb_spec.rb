require 'spec_helper'

RSpec.describe 'sufia/admin/admin_sets/_form_visibility.html.erb', type: :view do
  let(:admin_set) { create(:admin_set) }
  let(:permission_template) { Sufia::PermissionTemplate.find_or_create_by(admin_set_id: admin_set.id) }
  before do
    @form = Sufia::Forms::AdminSetForm.new(admin_set, permission_template)
    render
  end
  it "has the release form" do
    expect(rendered).to have_selector('#visibility input[type=radio][name="sufia_permission_template[release_period]"][value=now]')
    expect(rendered).to have_selector('#visibility input[type=radio][name="sufia_permission_template[release_period]"][value=fixed]')
    expect(rendered).to have_selector('#visibility input[type=radio][name="sufia_permission_template[release_varies]"][value=before]')
    expect(rendered).to have_selector('#visibility input[type=radio][name="sufia_permission_template[release_varies]"][value=embargo]')
    expect(rendered).to have_selector('#visibility select[name="sufia_permission_template[release_embargo]"]')
    expect(rendered).to have_selector('#visibility input[type=date][name="sufia_permission_template[release_date]"]')
  end
  it "has the visilibility form" do
    expect(rendered).to have_selector('#visibility input[type=radio][name="sufia_permission_template[visibility]"][value=open]')
    expect(rendered).to have_selector('#visibility input[type=radio][name="sufia_permission_template[visibility]"][value=authenticated]')
    expect(rendered).to have_selector('#visibility input[type=radio][name="sufia_permission_template[visibility]"][value=restricted]')
  end
end
