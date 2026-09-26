# frozen_string_literal: true
RSpec.describe Hyrax::Analytics::Ga4::Base do
  let(:visits) { Hyrax::Analytics::Ga4::VisitsDaily.new(start_date: 4.days.ago, end_date: Time.zone.today) }

  describe '#results' do
    context 'when the provider config is invalid (e.g. GA4 credentials unconfigured)' do
      before { allow(Hyrax::Analytics.config).to receive(:valid?).and_return(false) }

      it 'returns an empty result set without contacting the GA4 client' do
        expect(Hyrax::Analytics).not_to receive(:client)
        expect(visits.results).to eq([])
      end

      it 'zero-fills the date range instead of raising' do
        expect { visits.total_visits }.not_to raise_error
      end
    end

    context 'when the provider config is valid' do
      before do
        allow(Hyrax::Analytics.config).to receive(:valid?).and_return(true)
        allow(Hyrax::Analytics).to receive(:client).and_return(double(run_report: double(rows: []))) # rubocop:disable RSpec/VerifiedDoubles
      end

      it 'requests a report from the GA4 client' do
        visits.results
        expect(Hyrax::Analytics).to have_received(:client)
      end
    end
  end
end
