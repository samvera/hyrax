# frozen_string_literal: true
RSpec.describe Hyrax::UserProfilePresenter do
  let(:user) { create(:user) }
  let(:ability) { Ability.new(user) }
  let(:presenter) { described_class.new(user, ability) }

  describe "current_user?" do
    subject { presenter.current_user? }

    it { is_expected.to be true }
  end

  describe "trophies" do
    let(:work1) { create(:work, user: user) }
    let(:work2) { create(:work, user: user) }
    let(:work3) { create(:work, user: user) }
    let!(:trophy1) { user.trophies.create!(work_id: work1.id) }
    let!(:trophy2) { user.trophies.create!(work_id: work2.id) }
    let!(:trophy3) { user.trophies.create!(work_id: work3.id) }
    let!(:badtrophy) { user.trophies.create!(work_id: 'not_a_generic_work') }

    subject { presenter.trophies }

    it "has an array of presenters" do
      expect(subject).to all(be_kind_of Hyrax::TrophyPresenter)
      expect(subject.map(&:id)).to match_array [work1.id, work2.id, work3.id]
    end
  end
end
