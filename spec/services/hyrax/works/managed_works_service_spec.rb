# frozen_string_literal: true
RSpec.describe Hyrax::Works::ManagedWorksService, clean_repo: true do
  let(:current_ability) { instance_double(Ability, admin?: true) }
  let(:scope) { FakeSearchBuilderScope.new(current_ability: current_ability) }

  describe '.managed_works_count' do
    let!(:work) { valkyrie_create(:monograph, :public) }

    it 'returns number of works that can be managed' do
      expect(described_class.managed_works_count(scope: scope)).to eq(1)
    end
  end
end
