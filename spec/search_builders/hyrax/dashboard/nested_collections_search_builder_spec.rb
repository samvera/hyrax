RSpec.describe Hyrax::Dashboard::NestedCollectionsSearchBuilder do
  let(:collection) { double(id: '123', collection_type_gid: 'gid/abc') }
  let(:ability) { instance_double(Ability, admin?: true) }
  let(:scope) { double(current_ability: ability, blacklight_config: CatalogController.blacklight_config) }
  let(:access) { :read }
  let(:builder) { described_class.new(scope: scope, access: access, collection: collection) }

  describe '#query' do
    subject { builder.query }

    it { is_expected.to be_a(Hash) }
  end

  describe '#default_processor_chain' do
    subject { builder.default_processor_chain }

    it { is_expected.to include(:with_pagination) }
    it { is_expected.to include(:discovery_permissions) }
    it { is_expected.to include(:show_only_other_collections_of_the_same_collection_type) }
  end

  describe '#show_only_other_collections_of_the_same_collection_type' do
    let(:solr_params) { {} }

    subject { builder.show_only_other_collections_of_the_same_collection_type(solr_params) }

    it 'will exclude the given collection' do
      subject
      expect(solr_params.fetch(:fq)).to eq(["-{!terms f=id}#{collection.id}", "_query_:\"{!field f=collection_type_gid_ssim}#{collection.collection_type_gid}\""])
    end
  end
end
