# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Hyrax::FindObjectsViaSolrService do
  describe ".find_for_model_by_field_pairs", clean_repo: true do
    let(:collection_ids) { [collection1.id, collection2.id] }
    let(:field_pairs) do
      { id: collection_ids.map(&:to_s) }
    end
    subject(:results) { described_class.find_for_model_by_field_pairs(model: collection1.class, field_pairs: field_pairs, use_valkyrie: use_valkyrie) }

    context "when use_valkyrie is false", :active_fedora do
      let(:use_valkyrie) { false }
      let(:collection1) { create(:collection_lw, title: ['Foo']) }
      let(:collection2) { create(:collection_lw, title: ['Too']) }
      it "returns ActiveFedora objects matching the query" do
        expect(results).to be_kind_of Array
        expect(results.map(&:title)).to match_array [['Foo'], ['Too']]
      end
    end

    context "when use_valkyrie is true" do
      let(:use_valkyrie) { true }
      context "and objects were created with ActiveFedora", :active_fedora do
        let(:collection1) { create(:collection_lw, title: ['Foo']) }
        let(:collection2) { create(:collection_lw, title: ['Too']) }

        it "returns Valkyrie::Resources matching the query" do
          expect(results).to be_kind_of Array
          expect(results.map(&:title)).to match_array [['Foo'], ['Too']]
        end
      end
      context "and objects were created with Valkryie" do
        let(:collection1) { valkyrie_create(:hyrax_collection, title: ['Foo']) }
        let(:collection2) { valkyrie_create(:hyrax_collection, title: ['Too']) }

        it "returns Valkyrie::Resources matching the query" do
          expect(results).to be_kind_of Array
          expect(results.map(&:title)).to match_array [['Foo'], ['Too']]
        end
      end
    end
  end
end
