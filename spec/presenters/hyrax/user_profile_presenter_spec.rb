# frozen_string_literal: true
RSpec.describe Hyrax::UserProfilePresenter do
  subject(:presenter) { described_class.new(user, ability) }
  let(:ability)       { Ability.new(user) }
  let(:user)          { FactoryBot.create(:user) }

  its(:current_user?) { is_expected.to be true }

  describe "#trophies" do
    let(:work1) { FactoryBot.valkyrie_create(:hyrax_work, depositor: user.user_key) }
    let(:work2) { FactoryBot.valkyrie_create(:hyrax_work, depositor: user.user_key) }
    let(:work3) { FactoryBot.valkyrie_create(:hyrax_work, depositor: user.user_key) }

    before do
      user.trophies.create!(work_id: work1.id)
      user.trophies.create!(work_id: work2.id)
      user.trophies.create!(work_id: work3.id)
      user.trophies.create!(work_id: 'not_a_generic_work')
    end

    it "has an array of presenters" do
      expect(presenter.trophies).to all(be_kind_of Hyrax::TrophyPresenter)
    end

    it "matches only the trophied works" do
      FactoryBot.valkyrie_create(:hyrax_work, depositor: user.user_key) # not trophied

      expect(presenter.trophies.map(&:id))
        .to contain_exactly(work1.id, work2.id, work3.id)
    end
  end
end
