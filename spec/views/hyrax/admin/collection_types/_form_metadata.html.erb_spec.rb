# frozen_string_literal: true
RSpec.describe 'hyrax/admin/collection_types/_form_metadata.html.erb', type: :view do
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

  it "renders the name field" do
    expect(rendered).to have_content(I18n.t("simple_form.labels.collection_type.title"))
    expect(rendered).to have_selector("input#collection_type_title")
    expect(rendered).not_to have_css("#collection_type_title[disabled]")
  end

  it "renders the description field" do
    expect(rendered).to have_content(I18n.t("simple_form.labels.collection_type.description"))
    expect(rendered).to have_selector("textarea#collection_type_description")
  end
end
