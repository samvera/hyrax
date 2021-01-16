# frozen_string_literal: true
RSpec.describe Hyrax::AdminSetMemberService, clean_repo: true do
  subject(:builder) { described_class.new(scope: scope, collection: admin_set, params: { "id" => admin_set.id.to_s }) }
  let(:admin_set) { FactoryBot.build(:admin_set) }
  let(:scope) { FakeSearchBuilderScope.new(current_ability: Ability.new(user)) }
  let(:user) { FactoryBot.create(:admin) }

  describe '#available_member_works' do
    let!(:work1) { FactoryBot.create(:generic_work, admin_set: admin_set) }
    let!(:work2) { FactoryBot.create(:generic_work) }
    let!(:work3) { FactoryBot.create(:generic_work, admin_set: admin_set) }

    it 'returns the members of the admin set' do
      expect(builder.available_member_works.response[:docs])
        .to contain_exactly(include(id: work1.id), include(id: work3.id))
    end
  end
end
