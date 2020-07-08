# frozen_string_literal: true

RSpec.describe Hyrax::ManifestBuilderService, :clean_repo do
  # Presenters requires a whole lot of context and therefore a whole lot of preamble
  let(:id) { "123" }
  let(:manifest_url) { File.join("https://samvera.org", "show", id) }
  let(:solr_document) { { "_version_" => 1 } }
  let(:work_presenter) { double("Work Presenter") }
  let(:file_set_presenter) { double("File Set Presenter", id: "456") }
  let(:presenter) do
    double(
      'Presenter',
      id: id,
      solr_document: solr_document,
      work_presenters: [work_presenter],
      manifest_url: manifest_url,
      description: ["A Treatise on Coding in Samvera"],
      file_set_presenters: [file_set_presenter]
    )
  end
  subject { described_class.manifest_for(presenter: presenter) }

  describe ".as_json" do
    it "will be a Ruby hash" do
      expect(Rails.cache).not_to receive(:fetch)
      expect(subject).to be_a(Hash)
    end
  end
end
