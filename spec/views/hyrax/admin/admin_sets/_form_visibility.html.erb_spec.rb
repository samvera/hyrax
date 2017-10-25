RSpec.describe 'hyrax/admin/admin_sets/_form_visibility.html.erb', type: :view do
  let(:template) { stub_model(Hyrax::PermissionTemplate) }
  let(:pt_form) { Hyrax::Forms::PermissionTemplateForm.new(template) }

  before do
    @change_set = instance_double(Hyrax::AdminSetChangeSet,
                                  to_model: stub_model(AdminSet),
                                  permission_template: pt_form)
    render
  end

  it "has the form" do
    expect(rendered).to have_selector('#visibility input[type=radio][name="permission_template[release_period]"][value=now]')
    expect(rendered).to have_selector('#visibility input[type=radio][name="permission_template[release_period]"][value=fixed]')
    expect(rendered).to have_selector('#visibility input[type=radio][name="permission_template[release_varies]"][value=""]')
    expect(rendered).to have_selector('#visibility input[type=radio][name="permission_template[release_varies]"][value=before]')
    expect(rendered).to have_selector('#visibility input[type=radio][name="permission_template[release_varies]"][value=embargo]')
    expect(rendered).to have_selector('#visibility select[name="permission_template[release_embargo]"]')
    expect(rendered).to have_selector('#visibility input[type=date][name="permission_template[release_date]"]')
    expect(rendered).to have_selector('#visibility input[type=radio][name="permission_template[visibility]"][value=open]')
    expect(rendered).to have_selector('#visibility input[type=radio][name="permission_template[visibility]"][value=authenticated]')
    expect(rendered).to have_selector('#visibility input[type=radio][name="permission_template[visibility]"][value=restricted]')
  end
end
