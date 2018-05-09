RSpec.describe 'hyrax/admin/collection_types/_form_appearance.html.erb', type: :view do
  let(:collection_type) { create(:collection_type) }
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

  # This needs a little more work.
  it "renders the badge color options" do
    expect(rendered).to have_content(I18n.t("simple_form.labels.collection_type.badge_color"))
    expect(rendered).to have_selector("input#collection_type_badge_color")
  end
end
