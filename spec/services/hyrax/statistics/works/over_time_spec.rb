# frozen_string_literal: true
RSpec.describe Hyrax::Statistics::Works::OverTime do
  let(:service) do
    described_class.new(
                                      delta_x: 1,
                                      x_min: (Time.zone.today - 3.days).to_datetime,
                                      x_max: Time.zone.today.end_of_day.to_datetime,
                                      x_output: ->(x) { x.strftime('%F') }
                                    )
  end

  describe '#points', :clean_repo do
    before do
      create(:generic_work)
    end

    subject { service.points }

    xit 'is a list of points' do
      expect(subject.size).to eq 5
      expect(subject.first[1]).to eq 0
      expect(subject.to_a.last[1]).to eq 1
    end
  end
end
