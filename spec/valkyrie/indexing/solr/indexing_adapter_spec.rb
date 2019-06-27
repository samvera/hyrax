# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/indexing/solr/indexing_adapter'

RSpec.describe Valkyrie::Indexing::Solr::IndexingAdapter do
  subject(:adapter) { described_class.new }
  let(:persister) { Wings::Valkyrie::Persister.new(adapter: metadata_adapter) }
  let(:metadata_adapter) { Wings::Valkyrie::MetadataAdapter.new }

  describe "#connection" do
    it "returns connection" do
      expect(adapter.connection.uri.to_s).to include 'valkyrie-test'
    end
  end

  it "can save a resource" do
    resource = Hyrax::Resource.new
    saved = persister.save(resource: resource)
    adapter.save(resource: saved)
    expect(Hyrax::SolrService.query("*:*", use_valkyrie: true).map(&:id)).to eq [saved.id.to_s]
  end

  it "can save multiple resources at once" do
    resource = Hyrax::Resource.new
    resource2 = Hyrax::Resource.new
    results = persister.save_all(resources: [resource, resource2])
    adapter.save_all(resources: results)

    expect(Hyrax::SolrService.query("*:*", use_valkyrie: true).map(&:id)).to contain_exactly(*results.map(&:id).map(&:to_s))
  end

  it "can delete an object" do
    resource = Hyrax::Resource.new
    saved = persister.save(resource: resource)
    adapter.save(resource: saved)
    adapter.delete(resource: saved)
    expect(Hyrax::SolrService.query("*:*", use_valkyrie: true).count).to eq 0
  end

  it "can delete all objects" do
    resource = Hyrax::Resource.new
    resource2 = Hyrax::Resource.new
    saved = persister.save_all(resources: [resource, resource2])

    adapter.save_all(resources: saved)
    adapter.wipe!
    expect(Hyrax::SolrService.query("*:*", use_valkyrie: true).count).to eq 0
  end
end
