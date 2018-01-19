RSpec.describe Hyrax::Dashboard::NestedCollectionsSearchBuilder do
  let(:collection) { double(id: '123', collection_type_gid: 'gid/abc') }
  let(:scope) { double(current_ability: ability, blacklight_config: CatalogController.blacklight_config) }
  let(:builder) { described_class.new(scope: scope, access: access, collection: collection) }
  let(:access) { :read }
  let(:user) { create(:user) }
  let(:ability) { ::Ability.new(user) }

  describe '#query' do
    subject { builder.query }

    it { is_expected.to be_a(Hash) }
  end

  describe '#default_processor_chain' do
    subject { builder.default_processor_chain }

    it { is_expected.to include(:with_pagination) }
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

  describe '#gated_discovery_filters' do
    subject { builder.gated_discovery_filters(access, ability) }

    context 'when access is :deposit' do
      let(:access) { "deposit" }
      let!(:collection) { create(:collection, with_permission_template: attributes) }

      context 'and user has access' do
        let(:attributes) { { deposit_users: [user.user_key] } }

        it { is_expected.to eq ["{!terms f=id}#{collection.id}"] }
      end

      context 'and group has access' do
        let(:attributes) { { deposit_groups: ['registered'] } }

        it { is_expected.to eq ["{!terms f=id}#{collection.id}"] }
      end

      context "and user has no access" do
        let(:attributes) { true }

        it { is_expected.to eq ["{!terms f=id}"] }
      end
    end
  end
end
