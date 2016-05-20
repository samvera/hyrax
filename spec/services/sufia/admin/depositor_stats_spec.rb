require 'spec_helper'

describe Sufia::Admin::DepositorStats do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let!(:old_work) { create(:work, user: user1) }
  let(:two_days_ago_date) { Time.zone.now - 2.days }

  let(:start_date) { '' }
  let(:end_date) { '' }
  let!(:work1) { create(:work, user: user1) }
  let!(:work2) { create(:work, user: user2) }
  let!(:collection1) { create(:public_collection, user: user1) }

  before do
    allow(old_work).to receive(:create_date).and_return(two_days_ago_date.to_datetime)
    old_work.update_index
  end

  let(:service) { described_class.new(start_date, end_date) }

  describe "#depositors" do
    subject { service.depositors }

    context "when dates are empty" do
      it "gathers user deposits" do
        expect(subject).to eq [{ key: user1.user_key, deposits: 2, user: user1 },
                               { key: user2.user_key, deposits: 1, user: user2 }]
      end
    end

    context "when dates are present" do
      let(:start_date) { 1.day.ago.strftime("%Y-%m-%d") }
      let(:end_date) { 0.days.ago.strftime("%Y-%m-%d") }
      it "gathers user deposits during a date range" do
        expect(subject).to eq [{ key: user1.user_key, deposits: 1, user: user1 },
                               { key: user2.user_key, deposits: 1, user: user2 }]
      end
    end
  end

  describe "#query" do
    subject { service.send(:query) }

    it "sets facet.limit to the number of users" do
      allow(User).to receive(:count).and_return(14)
      expect(subject['facet.limit']).to eq 14
    end
  end
end
