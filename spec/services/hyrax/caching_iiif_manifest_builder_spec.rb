# frozen_string_literal: true

RSpec.describe Hyrax::CachingIiifManifestBuilder, :clean_repo do
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

  subject(:builder) { described_class.new }

  it 'hits the cache' do
    expect(Rails.cache).to receive(:fetch).and_yield

    builder.manifest_for(presenter: presenter)
  end
end
