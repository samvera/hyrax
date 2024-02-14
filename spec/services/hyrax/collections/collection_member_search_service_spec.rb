# frozen_string_literal: true
RSpec.describe Hyrax::Collections::CollectionMemberSearchService, clean_repo: true do
  subject(:builder) do
    described_class.new(scope: scope, collection: nestable_collection, params: { "id" => nestable_collection.id.to_s })
  end

  let(:current_ability) { instance_double(Ability, admin?: true) }
  let(:scope) { FakeSearchBuilderScope.new(current_ability: current_ability) }
  let!(:subcollection) { valkyrie_create(:hyrax_collection, :public) }

  let!(:nestable_collection) { valkyrie_create(:hyrax_collection, :public, members: [subcollection, work1, work3]) }
  let!(:work1) { valkyrie_create(:monograph) }
  let!(:work2) { valkyrie_create(:monograph) }
  let!(:work3) { valkyrie_create(:monograph) }

  describe '#available_member_subcollections' do
    it 'returns the members that are collections' do
      ids = builder.available_member_subcollections.response[:docs].map { |col| col[:id] }

      expect(ids).to contain_exactly(subcollection.id)
    end
  end

  describe '#available_member_works' do
    it 'returns the members that are collections' do
      ids = builder.available_member_works.response[:docs].map { |col| col[:id] }

      expect(ids).to contain_exactly(work1.id, work3.id)
    end
  end

  describe '#available_member_work_ids' do
    it 'returns the members ids that are works' do
      ids = builder.available_member_work_ids.response[:docs].map { |col| col[:id] }

      expect(ids).to contain_exactly(work1.id, work3.id)
    end
  end
end
