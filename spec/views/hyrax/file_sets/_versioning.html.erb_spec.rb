# frozen_string_literal: true
RSpec.describe 'hyrax/file_sets/_versioning.html.erb', type: :view do
  let(:file_set) { stub_model(FileSet) }
  let(:versioning_service) { Hyrax::VersioningService.new(resource: nil) }

  before do
    allow(view).to receive(:curation_concern).and_return(file_set)
    assign(:version_list, Hyrax::VersionListPresenter.new(versioning_service))
  end

  context "when versioning is supported" do
    before do
      allow(versioning_service).to receive(:supports_multiple_versions?).and_return(true)
      allow(versioning_service).to receive(:versions).and_return([])
      render
    end

    it "draws the new version form without error" do
      expect(rendered).to have_content t("hyrax.file_sets.versioning.choose_file")
      expect(rendered).to have_content t("hyrax.uploads.js_templates_versioning.options.messages.max_file_size")
      expect(rendered).to have_content "maxFileSize: #{Hyrax.config.uploader[:maxFileSize]}"
      expect(rendered).to have_content t("hyrax.file_sets.versioning.upload")
    end
  end

  context "when versioning is unsupported" do
    before do
      allow(versioning_service).to receive(:supports_multiple_versions?).and_return(false)
      render
    end

    it "does not draw the new version form" do
      expect(rendered).not_to have_content t("hyrax.file_sets.versioning.upload")
    end
  end
end
