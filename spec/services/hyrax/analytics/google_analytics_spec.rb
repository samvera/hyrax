RSpec.describe Hyrax::Analytics::GoogleAnalytics, :clean_repo do
  let(:query_date) { '2018-03-01' }
  let(:ga_connection) { instance_double(Google::Apis::AnalyticsreportingV4::AnalyticsReportingService) }
  let(:config) { { 'view_id' => 123 } }

  describe '.site_report' do
    let(:site_report_params) do
      { dimensions: ['date'],
        metrics: ['users', 'sessions'], # users is unique visitors
        page_size: 10_000,
        page_token: '0' }
    end

    it 'assigns default page_size and page token' do
      expect(described_class).to receive(:run_report).with(query_date, site_report_params)
      described_class.site_report(query_date, '0')
    end

    describe 'run report with multiple result pages' do
      let(:site_report_response) do
        Google::Apis::AnalyticsreportingV4::GetReportsResponse::Representation
          .new(Google::Apis::AnalyticsreportingV4::GetReportsResponse.new)
          .from_json(IO.read(fixture_path + '/analytics/site_response_with_next_token.json'))
      end
      it 'supports a result set with a next page token' do
        allow(described_class).to receive(:connection).and_return(ga_connection)
        allow(described_class).to receive(:config).and_return(config)
        allow(ga_connection).to receive(:batch_get_reports).and_return(site_report_response)
        expect(described_class.site_report(query_date, '0').fetch(:next_page_token)).to eq('5')
      end
    end

    describe 'run report without a next result page' do
      let(:site_report_response) do
        Google::Apis::AnalyticsreportingV4::GetReportsResponse::Representation
          .new(Google::Apis::AnalyticsreportingV4::GetReportsResponse.new)
          .from_json(IO.read(fixture_path + '/analytics/site_response_without_next_token.json'))
      end
      it 'supports a result set with a next page token' do
        allow(described_class).to receive(:connection).and_return(ga_connection)
        allow(described_class).to receive(:config).and_return(config)
        allow(ga_connection).to receive(:batch_get_reports).and_return(site_report_response)
        expect(described_class.site_report(query_date, '0').fetch(:next_page_token)).to eq('')
      end
    end
  end

  describe '.page_report' do
    before do
      create(:work_with_one_file, :public)
      create(:collection)
    end
    let(:page_report_params) do
      { dimensions: ['date', 'pagePath'],
        metrics: ['pageviews', 'users', 'sessions'], # users is unique visitors
        filters: 'ga:pagePath=~/concern/generic_works/,ga:pagePath=~/collections/,ga:pagePath=~/concern/file_sets/;'\
                 'ga:pagePath!~/concern/generic_works/*/edit,ga:pagePath!~/collections/*/edit,ga:pagePath!~/concern/file_sets/*/edit',
        page_size: 10_000,
        page_token: '0' }
    end

    it 'assigns default page_size, filters, and page token' do
      expect(described_class).to receive(:run_report).with(query_date, page_report_params)
      described_class.page_report(query_date, '0')
    end

    describe 'run report with multiple result pages' do
      let(:page_report_response) do
        Google::Apis::AnalyticsreportingV4::GetReportsResponse::Representation
          .new(Google::Apis::AnalyticsreportingV4::GetReportsResponse.new)
          .from_json(IO.read(fixture_path + '/analytics/page_response_with_next_token.json'))
      end
      it 'supports a result set with a next page token' do
        allow(described_class).to receive(:connection).and_return(ga_connection)
        allow(described_class).to receive(:config).and_return(config)
        allow(ga_connection).to receive(:batch_get_reports).and_return(page_report_response)
        expect(described_class.page_report(query_date, '0').fetch(:next_page_token)).to eq('15')
      end
    end

    describe 'run report without a next result page' do
      let(:page_report_response) do
        Google::Apis::AnalyticsreportingV4::GetReportsResponse::Representation
          .new(Google::Apis::AnalyticsreportingV4::GetReportsResponse.new)
          .from_json(IO.read(fixture_path + '/analytics/page_response_without_next_token.json'))
      end
      it 'supports a result set with a next page token' do
        allow(described_class).to receive(:connection).and_return(ga_connection)
        allow(described_class).to receive(:config).and_return(config)
        allow(ga_connection).to receive(:batch_get_reports).and_return(page_report_response)
        expect(described_class.page_report(query_date, '0').fetch(:next_page_token)).to eq('')
      end
    end
  end
end
