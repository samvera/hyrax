# frozen_string_literal: true
RSpec.describe Hyrax::Collections::ManagedCollectionsService, clean_repo: true do
  let(:current_ability) { instance_double(Ability, admin?: true) }
  let(:scope) { FakeSearchBuilderScope.new(current_ability: current_ability) }

  describe '.managed_collections_count' do
    before do
      FactoryBot.valkyrie_create(:hyrax_collection, :public)
    end

    it 'returns number of collections that can be managed' do
      expect(described_class.managed_collections_count(scope: scope)).to eq(1)
    end
  end
end
