# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/indexing/solr/indexing_adapter'

RSpec.describe Valkyrie::Indexing::Solr::IndexingAdapter do
  subject(:adapter) { described_class.new }
  let(:persister) { Wings::Valkyrie::Persister.new(adapter: metadata_adapter) }
  let(:metadata_adapter) { Wings::Valkyrie::MetadataAdapter.new }

  before do
    class CustomResource < Valkyrie::Resource
      include Valkyrie::Resource::AccessControls
      attribute :title
      attribute :creator
    end
  end
  after do
    Object.send(:remove_const, :CustomResource)
  end

  describe "#connection" do
    it "returns connection" do
      expect(adapter.connection.uri.to_s).to include 'valkyrie-test'
    end
  end

  it "can save a resource" do
    resource = CustomResource.new(title: "Carrots", creator: "Farmer MacGregor")
    saved = persister.save(resource: resource)
    adapter.save(resource: saved)
  end
end
