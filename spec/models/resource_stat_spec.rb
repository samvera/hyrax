RSpec.describe ResourceStat, type: :model do
  let(:args) do
    { date: 1.day.ago, pageviews: 25 }
  end

  subject { described_class.new(args) }

  it 'requires a date' do
    expect { described_class.create! }.to raise_error ActiveRecord::RecordInvalid
    expect { subject.save! }.not_to raise_error
  end
end
