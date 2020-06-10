# frozen_string_literal: true
RSpec.describe Hyrax::Statistics::Users::OverTime do
  before do
    create(:user, created_at: 1.week.ago)
    create(:user, created_at: 1.week.ago)
    create(:user, created_at: 2.weeks.ago)
  end

  let(:instance) do
    described_class.new(x_min: 3.weeks.ago,
                        x_output: ->(x) { x.strftime('%b %-d') })
  end

  describe "#points" do
    subject { instance.points }

    it "has the counts" do
      expect(subject.size).to eq 4
      expect(subject.to_a.first.last).to eq 1
      expect(subject.to_a.second.last).to eq 2
    end
  end
end
