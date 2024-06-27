# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/indexing/solr/indexing_adapter'

RSpec.describe Valkyrie::Indexing::Solr::IndexingAdapter, :clean_index, index_adapter: :solr_index do
  subject(:adapter) { Valkyrie::IndexingAdapter.find(:solr_index) }
  let(:resource) { FactoryBot.valkyrie_create(:hyrax_resource) }
  let(:resource2) { FactoryBot.valkyrie_create(:hyrax_resource) }
  let(:model_query) { "has_model_ssim:Hyrax\\:\\:Resource" }
  let(:expected_solr_core) { Hyrax.config.disable_wings ? 'koppie-test' : 'hyrax_test' }

  describe "#connection" do
    it "returns connection" do
      expect(adapter.connection.uri.to_s).to include expected_solr_core
    end
  end

  it "can save a resource" do
    adapter.save(resource: resource)
    expect(Hyrax::SolrService.query(model_query).map(&:id)).to eq [resource.id.to_s]
  end

  it "can save multiple resources at once" do
    adapter.save_all(resources: [resource, resource2])
    expect(Hyrax::SolrService.query(model_query).map(&:id)).to contain_exactly resource.id.to_s, resource2.id.to_s
  end

  it "can delete an object" do
    adapter.save(resource: resource)
    expect(Hyrax::SolrService.query(model_query).count).to eq 1
    adapter.delete(resource: resource)
    expect(Hyrax::SolrService.query(model_query).count).to eq 0
  end

  it "can delete all objects" do
    adapter.save_all(resources: [resource, resource2])
    expect(Hyrax::SolrService.query(model_query).count).to eq 2
    adapter.wipe!
    expect(Hyrax::SolrService.query("*:*").count).to eq 0
  end
end
