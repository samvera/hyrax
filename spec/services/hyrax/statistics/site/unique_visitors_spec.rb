RSpec.describe Hyrax::Statistics::Site::Sessions do
  before do
    ResourceStat.create(date: 1.week.ago, sessions: 20)
    ResourceStat.create(date: 2.days.ago, sessions: 10)
    ResourceStat.create(date: 1.week.ago, sessions: 5, resource_id: '199', user_id: 123)
  end

  let(:instance) do
    described_class.new(x_min: 3.weeks.ago,
                        x_output: ->(x) { x.strftime('%b %-d') })
  end

  describe "#points" do
    subject { instance.points }

    it "has session counts" do
      expect(subject.size).to eq 4
      expect(subject.to_a.second.last).to eq 20
      expect(subject.to_a.third.last).to eq 10
    end
  end
end
