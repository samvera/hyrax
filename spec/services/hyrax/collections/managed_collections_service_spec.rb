# frozen_string_literal: true
RSpec.describe Hyrax::Collections::ManagedCollectionsService do
  let(:scope) { FakeSearchBuilderScope.new(current_ability: current_ability) }
  let(:current_ability) { instance_double(Ability, admin?: true) }

  describe '.managed_collections_count' do
    it 'returns number of collections that can be managed' do
      expect { FactoryBot.valkyrie_create(:hyrax_collection, :public) }
        .to change { described_class.managed_collections_count(scope: scope) }
        .by 1
    end
  end
end
