RSpec.describe 'hyrax/admin/collection_types/_form_settings.html.erb', type: :view do
  let(:collection_type) { Hyrax::CollectionType.new }
  let(:collection_type_form) { Hyrax::Forms::Admin::CollectionTypeForm.new }

  let(:form) do
    view.simple_form_for(collection_type, url: '/update') do |fs_form|
      return fs_form
    end
  end

  before do
    assign(:form, collection_type_form)
    allow(view).to receive(:f).and_return(form)
    render
  end

  it "renders the intructions and warning" do
    expect(rendered).to have_content(I18n.t("hyrax.admin.collection_types.form_settings.instructions"))
    expect(rendered).to have_content(I18n.t("hyrax.admin.collection_types.form_settings.warning"))
  end

  it "renders the checkboxes" do
    expect(rendered).to have_selector("input#collection_type_nestable")
    expect(rendered).to have_selector("input#collection_type_discoverable")
    expect(rendered).to have_selector("input#collection_type_sharable")
    expect(rendered).to have_selector("input#collection_type_require_membership")
    expect(rendered).to have_selector("input#collection_type_allow_multiple_membership")
    expect(rendered).to have_selector("input#collection_type_assigns_workflow")
    expect(rendered).to have_selector("input#collection_type_assigns_visibility")
  end
end
