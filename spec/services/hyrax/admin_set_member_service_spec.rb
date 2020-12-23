# frozen_string_literal: true
RSpec.describe Hyrax::AdminSetMemberService, clean_repo: true do
  subject(:builder) { described_class.new(scope: scope, collection: admin_set, params: { "id" => admin_set.id.to_s }) }
  let(:admin_set) { FactoryBot.build(:admin_set) }
  let(:current_ability) { instance_double(Ability, admin?: true) }
  let(:scope) { FakeSearchBuilderScope.new(current_ability: current_ability) }

  describe '#available_member_works' do
    let!(:work1) { create(:generic_work, admin_set: admin_set) }
    let!(:work2) { create(:generic_work) }
    let!(:work3) { create(:generic_work, admin_set: admin_set) }

    it 'returns the members of the admin set' do
      ids = builder.available_member_works.response[:docs].map { |col| col[:id] }

      expect(ids).to contain_exactly(work1.id, work3.id)
    end
  end
end
