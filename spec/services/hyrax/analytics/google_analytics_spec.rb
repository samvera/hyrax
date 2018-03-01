RSpec.describe Hyrax::Analytics::GoogleAnalytics do
  let(:query_date) { '2018-03-01' }
  let(:pageview_query_params) do
    { dimensions: ['date'],
      metrics: ['pageviews', 'users'], # users is unique visitors
      filters: 'ga:pagePath=~' + Rails.application.routes.url_helpers.polymorphic_path(object) }
  end

  describe 'Work API calls' do
    let(:object) { create(:work) }

    describe 'work pageviews' do
      it 'sends the correct query paramaters' do
        expect(described_class).to receive(:run_report).with(query_date, pageview_query_params)
        described_class.pageviews(query_date, object)
      end
    end
  end

  describe 'FileSet API calls' do
    let(:object) { create(:file_set) }

    describe 'FileSet pageviews' do
      it 'sends the correct query paramaters' do
        expect(described_class).to receive(:run_report).with(query_date, pageview_query_params)
        described_class.pageviews(query_date, object)
      end
    end

    describe 'FileSet downloads' do
      let(:download_query_params) do
        { dimensions: ['eventCategory', 'eventAction', 'eventLabel', 'date'],
          metrics: ['totalEvents', 'uniqueEvents'],
          filters: 'ga:eventLabel==' + object.id.to_s }
      end

      it 'sends the correct query paramaters' do
        expect(described_class).to receive(:run_report).with(query_date, pageview_query_params)
        described_class.pageviews(query_date, object)
      end
    end
  end

  describe '.connection' do
    it 'is a pending example'
  end

  describe '.pageviews' do
    it 'is a pending example'
  end

  describe '.downloads' do
    it 'is a pending example'
  end

  describe '.unique_visitors' do
    it 'is a pending example'
  end

  describe '.returning_visitors' do
    it 'is a pending example'
  end
end
