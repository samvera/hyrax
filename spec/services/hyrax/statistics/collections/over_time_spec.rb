# frozen_string_literal: true
RSpec.describe Hyrax::Statistics::Collections::OverTime do
  subject(:service) { described_class.new }

  describe "#points", :clean_repo do
    before { FactoryBot.valkyrie_create(:hyrax_collection) }

    shared_examples('test list of points') do
      it "is a list of points" do
        expect(service.points.size).to eq 5
        expect(service.points.first[1]).to eq 0
        expect(service.points.to_a.last[1]).to eq 1
      end
    end

    context 'ActiveFedora environment', :active_fedora do
      include_examples 'test list of points'
    end

    # NOTE: Hyrax::AbstractTypeRelation inherits from ActiveFedora::Relation. When the code attempts to run
    #   `AbstractTypeRelation.new(allowable_types: [Hyrax.config.collection_class])` in a Valkyrie environment,
    #   it quietly fails with `#<NoMethodError: undefined method `solr_query_handler' for Monograph:Class> rescued
    #   during inspection` and returns nil.
    context 'Valkyrie environment' do
      # include_examples 'test list of points'
    end
  end
end
