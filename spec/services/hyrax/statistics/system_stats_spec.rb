# frozen_string_literal: true
RSpec.describe Hyrax::Statistics::SystemStats do
  let(:user1) { create(:user) }
  let(:start_date) { nil }
  let(:end_date) { nil }

  describe ".recent_users" do
    let!(:user2) { create(:user) }

    let(:two_days_ago_date) { 2.days.ago.beginning_of_day }
    let(:one_day_ago_date) { 1.day.ago.end_of_day }

    let(:depositor_count) { nil }

    subject { described_class.recent_users(limit: depositor_count, start_date: start_date, end_date: end_date) }

    context "without dates" do
      let(:mock_order) { double }
      let(:mock_limit) { double }

      it "defaults to latest 5 users" do
        expect(mock_order).to receive(:limit).with(5).and_return(mock_limit)
        expect(User).to receive(:order).with('created_at DESC').and_return(mock_order)
        is_expected.to eq mock_limit
      end
    end

    context "with start date" do
      let(:start_date) { two_days_ago_date }

      it "allows queries  without an end date " do
        expect(User).to receive(:recent_users).with(two_days_ago_date, nil).and_return([user2])
        is_expected.to eq([user2])
      end
    end
    context "with start date and end date" do
      let(:start_date) { two_days_ago_date }
      let(:end_date) { one_day_ago_date }

      it "queries" do
        expect(User).to receive(:recent_users).with(two_days_ago_date, one_day_ago_date).and_return([user2])
        is_expected.to eq([user2])
      end
    end
  end
end
