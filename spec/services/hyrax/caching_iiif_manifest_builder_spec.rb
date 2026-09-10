# frozen_string_literal: true

RSpec.describe Hyrax::CachingIiifManifestBuilder, :clean_repo do
  let(:id) { "123" }
  let(:manifest_url) { File.join("https://samvera.org", "show", id) }
  let(:etag) { 'my_etag' }
  let(:work_presenter) { double("Work Presenter") }
  let(:file_set_presenter) { double("File Set Presenter", id: "456") }

  let(:presenter) do
    double(
      'Presenter',
      id: id,
      version: etag,
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

  it 'defaults to the configured manifest factory' do
    allow(Hyrax.config).to receive(:iiif_manifest_factory).and_return(::IIIFManifest::V3::ManifestFactory)

    expect(builder.manifest_factory).to eq ::IIIFManifest::V3::ManifestFactory
  end

  context 'with a real cache store' do
    subject(:builder) { described_class.new(iiif_manifest_factory: factory) }
    let(:factory) { double('manifest factory') }
    let(:manifest) { double('manifest', to_h: { 'label' => 'moomin' }) }

    before do
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      allow(factory).to receive(:new).and_return(manifest)
    end

    it 'builds the manifest only once for repeated calls' do
      2.times { builder.manifest_for(presenter: presenter) }

      expect(factory).to have_received(:new).once
    end

    it 'rebuilds when the presenter version changes' do
      builder.manifest_for(presenter: presenter)
      allow(presenter).to receive(:version).and_return('changed_etag')
      builder.manifest_for(presenter: presenter)

      expect(factory).to have_received(:new).twice
    end
  end
end
