require 'spec_helper'

RSpec.describe Hyrax::Stats::WorkStatusSearchBuilder do
  let(:context) do
    double(blacklight_config: CatalogController.blacklight_config,
           current_ability: ability)
  end
  let(:ability) do
    instance_double(Ability, admin?: true)
  end
  let(:instance) { described_class.new(context) }

  describe "#query" do
    subject { instance.query }

    let(:stub_relation) do
      instance_double(Hyrax::WorkRelation,
                      search_model_clause: "(model clauses)")
    end

    before do
      # Prevent the stub relation from returning different filters depending on
      # how many models have been generated
      allow(instance).to receive(:work_relation).and_return(stub_relation)
    end

    it "sets required parameters" do
      expect(subject['facet.field']).to eq ["suppressed_bsi"]
      expect(subject['fq']).to eq "(model clauses)"
      expect(subject['facet.missing']).to eq true
      expect(subject['rows']).to eq 0
    end
  end
end
