require 'spec_helper'

RSpec.describe 'hyrax/admin/admin_sets/_form.html.erb', type: :view do
  let(:admin_set) { stub_model(AdminSet) }
  before do
    @form = Hyrax::Forms::AdminSetForm.new(admin_set)
    stub_template('hyrax/admin/admin_sets/_form_participants.html.erb' => 'participant tab')
    stub_template('hyrax/admin/admin_sets/_form_visibility.html.erb' => 'visibility tab')
    stub_template('hyrax/admin/admin_sets/_form_workflow.html.erb' => 'workflow tab')
    render
  end
  it "has 4 tabs" do
    expect(rendered).to have_selector('#description')
    expect(rendered).to have_content('participant tab')
    expect(rendered).to have_content('visibility tab')
    expect(rendered).to have_content('workflow tab')

    # metadata fields
    expect(rendered).to have_selector('input[type=text][name="admin_set[title]"]')
    expect(rendered).to have_selector('textarea[name="admin_set[description]"]')

    # hint text
    expect(rendered).to have_content("A name to aid in identifying the Administrative Set and to distinguish it from other Administrative Sets in the repository.")
  end
end
