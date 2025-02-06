# frozen_string_literal: true
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

    context 'with alternatate class' do
      subject(:service) do
        described_class.new(filters, limit, by_depositor: by_depositor_class)
      end

      let(:by_depositor_class) { spy('ByDepositor') }

      it 'retrieves active_users from the class' do
        service.active_users

        expect(by_depositor_class).to have_received(:query).with(limit: limit)
      end
    end
  end

  describe "#top_formats" do
    it 'delegates to Hyrax::Statistics::FileSets::ByFormat.query' do
      expect(Hyrax::Statistics::FileSets::ByFormat).to receive(:query).with(limit: limit).and_return(:query_response)
      expect(service.top_formats).to eq(:query_response)
    end

    context 'with alternatate class' do
      subject(:service) do
        described_class.new(filters, limit, by_format: by_format)
      end

      let(:by_format) { spy('ByFormat') }

      it 'retrieves formats from the class' do
        service.top_formats

        expect(by_format).to have_received(:query).with(limit: limit)
      end
    end
  end

  describe "#works_count" do
    it 'delegates to Hyrax::Statistics::Works::Count.by_permission' do
      expect(Hyrax::Statistics::Works::Count).to receive(:by_permission).with(start_date: service.start_date, end_date: service.end_date).and_return(:query_response)
      expect(service.works_count).to eq(:query_response)
    end

    context 'with alternatate class' do
      subject(:service)   { described_class.new(filters, limit, works_counter: works_counter) }
      let(:works_counter) { spy('Works::Count') }

      it 'retrieves count from the class' do
        service.works_count

        expect(works_counter)
          .to have_received(:by_permission)
          .with(start_date: service.start_date, end_date: service.end_date)
      end
    end
  end

  describe "#depositors" do
    it 'delegates to Hyrax::Statistics::Depositors::Summary.depositors' do
      expect(Hyrax::Statistics::Depositors::Summary).to receive(:depositors).with(start_date: service.start_date, end_date: service.end_date).and_return(:query_response)
      expect(service.depositors).to eq(:query_response)
    end

    context 'with alternatate class' do
      subject(:service) do
        described_class.new(filters, limit, depositor_summary: summary_class)
      end

      let(:summary_class) { spy('depositor summary class') }

      it 'retrieves depositors from the class' do
        service.depositors

        expect(summary_class)
          .to have_received(:depositors)
          .with(start_date: service.start_date, end_date: service.end_date)
      end
    end
  end

  describe "#recent_users" do
    it 'delegates to Hyrax::Statistics::SystemStats.recent_users' do
      expect(Hyrax::Statistics::SystemStats).to receive(:recent_users).with(limit: limit, start_date: service.start_date, end_date: service.end_date).and_return(:query_response)
      expect(service.recent_users).to eq(:query_response)
    end

    context 'with alternatate class' do
      subject(:service) do
        described_class.new(filters, limit, system_stats: system_stats)
      end

      let(:system_stats) { spy('SystemStats') }

      it 'retrieves users from the class' do
        service.recent_users

        expect(system_stats)
          .to have_received(:recent_users)
          .with(limit: limit, start_date: service.start_date, end_date: service.end_date)
      end
    end
  end

  describe '#date_filter_string' do
    subject { service.date_filter_string }

    context "default range" do
      it { is_expected.to eq 'unfiltered' }
    end

    context "with a start and no end date" do
      let(:start_date) { '2015-12-14' }
      let(:today) { Time.zone.today.to_date.to_formatted_s(:standard) }

      it { is_expected.to eq "12/14/2015 to #{today}" }
    end

    context 'with start and end dates' do
      let(:start_date) { '2015-12-14' }
      let(:end_date) { '2016-05-12' }

      it { is_expected.to eq '12/14/2015 to 05/12/2016' }
    end
  end
end
