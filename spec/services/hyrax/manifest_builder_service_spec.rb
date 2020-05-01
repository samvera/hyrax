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
  subject { described_class.as_json(presenter: presenter, cache_manifest: cache_manifest) }

  describe ".as_json" do
    context 'with cache_manifest == true' do
      let(:cache_manifest) { true }
      it "will be a Ruby hash" do
        expect(Rails.cache).to receive(:fetch).and_yield
        expect(subject).to be_a(Hash)
      end
    end

    context 'with cache_manifest == false' do
      let(:cache_manifest) { false }
      it "will be a Ruby hash" do
        expect(Rails.cache).not_to receive(:fetch)
        expect(subject).to be_a(Hash)
      end
    end
  end
end
