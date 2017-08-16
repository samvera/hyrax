RSpec.describe Hyrax::AdminStatsPresenter do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  let(:one_day_ago_date)  { Time.zone.now - 1.day }
  let(:two_days_ago_date) { Time.zone.now - 2.days }
  let(:start_date) { '' }
  let(:end_date) { '' }

  let(:filters) { { start_date: start_date, end_date: end_date } }
  let(:limit) { 5 }
  let(:service) { described_class.new(filters, limit) }

  describe '#active_users' do
    it 'delegates to Hyrax::Statistics::Works::ByDepositor.query' do
      expect(Hyrax::Statistics::Works::ByDepositor).to receive(:query).with(limit: limit).and_return(:query_response)
      expect(service.active_users).to eq(:query_response)
    end
  end

  describe "#top_formats" do
    it 'delegates to Hyrax::Statistics::FileSets::ByFormat.query' do
      expect(Hyrax::Statistics::FileSets::ByFormat).to receive(:query).with(limit: limit).and_return(:query_response)
      expect(service.top_formats).to eq(:query_response)
    end
  end

  describe "#works_count" do
    it 'delegates to Hyrax::Statistics::Works::Count.by_permission' do
      expect(Hyrax::Statistics::Works::Count).to receive(:by_permission).with(start_date: service.start_date, end_date: service.end_date).and_return(:query_response)
      expect(service.works_count).to eq(:query_response)
    end
  end

  describe "#depositors" do
    it 'delegates to Hyrax::Statistics::Depositors::Summary.depositors' do
      expect(Hyrax::Statistics::Depositors::Summary).to receive(:depositors).with(start_date: service.start_date, end_date: service.end_date).and_return(:query_response)
      expect(service.depositors).to eq(:query_response)
    end
  end

  describe "#recent_users" do
    it 'delegates to Hyrax::Statistics::SystemStats.recent_users' do
      expect(Hyrax::Statistics::SystemStats).to receive(:recent_users).with(limit: limit, start_date: service.start_date, end_date: service.end_date).and_return(:query_response)
      expect(service.recent_users).to eq(:query_response)
    end
  end

  describe '#date_filter_string' do
    subject { service.date_filter_string }

    context "default range" do
      it { is_expected.to eq 'unfiltered' }
    end

    context "with a start and no end date" do
      let(:start_date) { '2015-12-14' }
      let(:today) { Time.zone.today.to_date.to_s(:standard) }

      it { is_expected.to eq "12/14/2015 to #{today}" }
    end

    context 'with start and end dates' do
      let(:start_date) { '2015-12-14' }
      let(:end_date) { '2016-05-12' }

      it { is_expected.to eq '12/14/2015 to 05/12/2016' }
    end
  end
end
