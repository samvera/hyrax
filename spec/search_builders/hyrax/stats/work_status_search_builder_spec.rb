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

    before do
      # Prevent the search builder from returning different filters depending on
      # how many models have been generated
      allow_any_instance_of(Hyrax::FilterByType).to receive(:models_to_solr_clause).and_return("(model clauses)")
    end

    it "sets required parameters" do
      expect(subject['facet.field']).to eq ["suppressed_bsi"]
      expect(subject['fq']).to eq ["{!terms f=internal_resource_ssim}(model clauses)"]
      expect(subject['facet.missing']).to eq true
      expect(subject['rows']).to eq 0
    end
  end
end
