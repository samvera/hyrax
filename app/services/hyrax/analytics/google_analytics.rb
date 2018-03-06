require 'google/apis/analyticsreporting_v4'
include Google::Apis::AnalyticsreportingV4

module Hyrax
  module Analytics
    class GoogleAnalytics < Hyrax::Analytics::Base
      REQUIRED_KEYS = %w[privkey_path view_id].freeze

      class << self
        attr_accessor :config
      end

      def self.pageviews(start_date, object)
        params = { dimensions: ['date'],
                   metrics: ['pageviews', 'users'], # users is unique visitors
                   filters: 'ga:pagePath=~' + Rails.application.routes.url_helpers.polymorphic_path(object) }
        run_report(start_date, params)
      end

      def self.downloads(start_date, object)
        params = { dimensions: ['eventCategory', 'eventAction', 'eventLabel', 'date'],
                   metrics: ['totalEvents', 'uniqueEvents'],
                   filters: 'ga:eventLabel==' + object.id.to_s }
        run_report(start_date, params)
      end

      # @return [Boolean] are all the required values present?
      def self.valid?
        config_keys = config.keys
        REQUIRED_KEYS.all? { |required| config_keys.include?(required) }
      end

      def self.connection
        setup_and_authorize
      end

      def self.run_report(start_date, query_params)
        unless connection
          Rails.logger.error("Google Analytics Reporting Service has not been established. Unable to fetch report.")
          return []
        end

        date_ranges = [DateRange.new(start_date: format_date(start_date), end_date: 'today')]
        dimensions = query_params[:dimensions].map { |d| Dimension.new(name: 'ga:' + d) }
        metrics = query_params[:metrics].map { |m| Metric.new(expression: 'ga:' + m) }

        request = report_request(date_ranges, dimensions, metrics, query_params[:filters])
        response = connection.batch_get_reports(request)
        return [] if response.try(:reports).try(:first).try(:data).try(:rows).blank?
        stats_rows(response, query_params)
      end
      private_class_method :run_report

      def self.report_request(date_ranges, dimensions, metrics, filters)
        GetReportsRequest.new(
          report_requests: [ReportRequest.new(view_id: 'ga:' + config['view_id'].to_s,
                                              dimensions: dimensions,
                                              metrics: metrics,
                                              date_ranges: date_ranges,
                                              sort: 'ga:date',
                                              filters_expression: filters)]
        )
      end
      private_class_method :report_request

      def self.format_date(date)
        if date.is_a?(String)
          date
        else
          date.strftime('%Y-%m-%d')
        end
      end
      private_class_method :format_date

      def self.stats_rows(response, query_params)
        output = []
        response.reports.first.data.rows.each do |row|
          output_row = OpenStruct.new
          output << openstruct_row(row.to_h, output_row, query_params)
        end
        output
      end
      private_class_method :stats_rows

      def self.openstruct_row(row, output_row, query_params)
        Rails.logger.error 'Hyrax::Analytics.GoogleAnalytics - Bad Google Analytics data' if row[:dimensions].blank? || row[:metrics].blank?
        query_params[:dimensions].zip(row[:dimensions]).each do |term, value|
          output_row[term] = value
        end
        query_params[:metrics].zip(row[:metrics].first[:values]).each do |term, value|
          output_row[term] = value
        end
        output_row
      end
      private_class_method :openstruct_row

      # Return an authorized Google Analytics Reporting Service
      def self.setup_and_authorize
        unless File.exist?(config['privkey_path'])
          raise "Private key file for Google Analytics was expected at '#{config['privkey_path']}',\
                but no file was found."
        end
        analytics = Google::Apis::AnalyticsreportingV4::AnalyticsReportingService.new
        credentials = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: File.open(config['privkey_path']))
        credentials.scope = 'https://www.googleapis.com/auth/analytics.readonly'
        analytics.authorization = credentials.fetch_access_token!({})["access_token"]
        analytics
      end
      private_class_method :setup_and_authorize

      REQUIRED_KEYS.each do |key|
        class_eval %{ def self.#{key};  @config.fetch('#{key}'); end }
      end
    end
  end
end
