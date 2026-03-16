# frozen_string_literal: true
RSpec.describe 'hyrax/admin/admin_sets/_form.html.erb', type: :view do
  let(:admin_set) { stub_model(AdminSet) }
  let(:form) { Hyrax::Forms::AdminSetForm.new(admin_set, double, double) }

  before do
    assign(:form, form)
    stub_template('hyrax/admin/admin_sets/_form_participants.html.erb' => 'participant tab')
    stub_template('hyrax/admin/admin_sets/_form_visibility.html.erb' => 'visibility tab')
    stub_template('hyrax/admin/admin_sets/_form_workflow.html.erb' => 'workflow tab')
    allow(form).to receive(:thumbnail_title).and_return("James Joyce")
    allow(form).to receive(:contexts).and_return([])
    allow(admin_set).to receive(:member_ids).and_return(['123', '456'])
    # stub_model doesn't always stub new_record correctly on ActiveFedora models
    allow(admin_set).to receive(:new_record).and_return(false)
    render
  end

  it "has 4 tabs" do
    expect(rendered).to have_selector('#description')
    expect(rendered).to have_content('participant tab')
    expect(rendered).to have_content('visibility tab')
    expect(rendered).to have_content('workflow tab')

    # metadata fields
    expect(rendered).to have_selector('input[type=text][name="admin_set[title]"]')
    expect(rendered).to have_selector('input[type=text][name="admin_set[description]"]')
    expect(rendered).to have_selector('input[type=text][name="admin_set[thumbnail_id]"][data-text="James Joyce"]')

    # hint text
    expect(rendered).to have_content("A name to aid in identifying the Administrative Set and to distinguish it from other Administrative Sets in the repository.")
  end
end
