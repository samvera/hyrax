# frozen_string_literal: true
RSpec.describe 'hyrax/collections/_sort_and_per_page.html.erb', type: :view do
  let(:subject) { 'hyrax/collections/sort_and_per_page' }
  let(:collection) { instance_double(Collection) }

  before do
    allow(view).to receive(:show_sort_and_per_page?).and_return(true)
    allow(view).to receive(:collection_path).and_return("collection/path")
    stub_template('_view_type_group.erb' => "")
  end

  context "when there are multiple sort fields" do
    let(:active_sort_fields) do
      {
        "sort field value 1" => Blacklight::Configuration::SortField.new(label: "sort field label 1"),
        "sort field value 2" => Blacklight::Configuration::SortField.new(label: "sort field label 2")
      }
    end

    it "renders the sort options without any selected when no sort param given" do
      render(subject, collection: collection, collection_member_sort_fields: active_sort_fields)
      expect(rendered).to have_select('sort', options: ["sort field label 1", "sort field label 2"], with_selected: [])
    end

    it "renders the sort options with the correct option selected when a valid sort param given" do
      allow(view).to receive(:params).and_return(sort: "sort field value 1")
      render(subject, collection: collection, collection_member_sort_fields: active_sort_fields)
      expect(rendered).to have_select('sort', options: ["sort field label 1", "sort field label 2"], with_selected: ["sort field label 1"])
    end

    it "renders the sort options without any selected when an invalid sort param given" do
      allow(view).to receive(:params).and_return(sort: "sort field value DNE")
      render(subject, collection: collection, collection_member_sort_fields: active_sort_fields)
      expect(rendered).to have_select('sort', options: ["sort field label 1", "sort field label 2"], with_selected: [])
    end
  end

  context "when there is only one sort field" do
    let(:active_sort_fields) do
      {
        "sort field value 1" => Blacklight::Configuration::SortField.new(label: "sort field label 1")
      }
    end

    it "does not render sort options" do
      render(subject, collection: collection, collection_member_sort_fields: active_sort_fields)
      expect(rendered).not_to have_select('sort')
    end
  end

  context "when there are no sort fields" do
    let(:active_sort_fields) do
      {}
    end

    it "does not render sort options" do
      render(subject, collection: collection, collection_member_sort_fields: active_sort_fields)
      expect(rendered).not_to have_select('sort')
    end
  end
end
