# frozen_string_literal: true
RSpec.describe Hyrax::Admin::UserActivityPresenter do
  start_date = Time.zone.today - 6.days
  end_date = Time.zone.today
  let(:instance) { described_class.new(start_date, end_date) }

  describe "#to_json" do
    subject { instance.to_json }

    let(:users) do
      instance_double(Hyrax::Statistics::Users::OverTime,
                      points: [[Time.zone.today - 3.days, '12']])
    end

    before do
      allow(Hyrax::Statistics::Users::OverTime).to receive(:new).and_return(users)
    end

    it "returns points" do
      expect(subject).to eq "[{\"y\":\"#{Time.zone.today - 3.days}\",\"a\":\"12\",\"b\":null}]"
    end
  end
end
