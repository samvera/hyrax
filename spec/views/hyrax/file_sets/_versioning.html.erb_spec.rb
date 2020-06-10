# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/_versioning.html.erb', type: :view do
  let(:file_set) { stub_model(FileSet) }

  before do
    allow(file_set).to receive(:files).and_return([])
    allow(view).to receive(:curation_concern).and_return(file_set)
    assign(:version_list, [])
    render
  end

  context "without additional users" do
    it "draws the new version form without error" do
      expect(rendered).to have_content t("hyrax.file_sets.versioning.choose_file")
      expect(rendered).to have_content t("hyrax.uploads.js_templates_versioning.options.messages.max_file_size")
      expect(rendered).to have_content "maxFileSize: #{Hyrax.config.uploader[:maxFileSize]}"
    end
  end
end
