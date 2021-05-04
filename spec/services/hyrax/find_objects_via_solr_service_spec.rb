# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Hyrax::FindObjectsViaSolrService do
  describe ".find_for_model_by_field_pairs", clean_repo: true do
    let(:collection1) { valkyrie_create(:hyrax_collection, title: ['Foo']) }
    let(:collection2) { valkyrie_create(:hyrax_collection, title: ['Too']) }
    let(:collection_ids) { [collection1.id, collection2.id] }
    let(:field_pairs) do
      { id: collection_ids.map(&:to_s) }
    end

    it "returns ActiveFedora objects matching the query" do
      expect(described_class.find_for_model_by_field_pairs(model: ::Collection, field_pairs: field_pairs, use_valkyrie: false).map(&:title)).to match_array [['Foo'], ['Too']]
    end
    it "returns Valkyrie::Resources matching the query" do
      expect(described_class.find_for_model_by_field_pairs(model: ::Collection, field_pairs: field_pairs, use_valkyrie: true).map(&:title)).to match_array [['Foo'], ['Too']]
    end
  end
end
