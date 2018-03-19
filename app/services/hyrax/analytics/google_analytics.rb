require 'google/apis/analyticsreporting_v4'
include Google::Apis::AnalyticsreportingV4

module Hyrax
  module Analytics
    class GoogleAnalytics < Hyrax::Analytics::Base
      REQUIRED_KEYS = %w[privkey_path view_id].freeze
      # we ask for the maximum number of results in a single query
      PAGE_SIZE = 10_000

      class << self
        include ActionDispatch::Routing::PolymorphicRoutes
        include Rails.application.routes.url_helpers
        attr_accessor :config
      end

      def self.page_report(start_date, page_token)
        params = { dimensions: ['date', 'pagePath'],
                   metrics: ['pageviews', 'users', 'sessions'], # users is unique visitors
                   filters: filters,
                   page_size: PAGE_SIZE,
                   page_token: page_token }
        run_report(start_date, params)
      end

      def self.site_report(start_date, page_token)
        params = { dimensions: ['date'],
                   metrics: ['users', 'sessions'], # users is unique visitors
                   page_size: PAGE_SIZE,
                   page_token: page_token }
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
          return {}
        end

        date_ranges = [DateRange.new(start_date: format_date(start_date), end_date: 'today')]
        dimensions = query_params[:dimensions].map { |d| Dimension.new(name: 'ga:' + d) }
        metrics = query_params[:metrics].map { |m| Metric.new(expression: 'ga:' + m) }

        request = report_request(date_ranges, dimensions, metrics, query_params[:page_token], query_params[:filters])
        response = connection.batch_get_reports(request)
        return {} if response.try(:reports).try(:first).try(:data).try(:rows).blank?

        next_page_token = response.reports.first.try(:next_page_token) || ''
        { rows: stats_rows(response, query_params), next_page_token: next_page_token }
      end
      private_class_method :run_report

      # Google Analytics filters to apply to page_report queries
      # Google specifies that OR conditions are comma-separate and AND conditions are colon
      # This filter query is saying "Include everything in known model paths AND exclude /edit subpaths"
      def self.filters
        paths = super
        include_filters(paths) + ';' + exclude_filters(paths)
      end
      private_class_method :filters

      def self.include_filters(paths)
        paths.map { |p| "ga:pagePath=~#{p}" }.join(',')
      end
      private_class_method :include_filters

      def self.exclude_filters(paths)
        paths.map { |p| "ga:pagePath!~#{p}*/edit" }.join(',')
      end
      private_class_method :include_filters

      def self.report_request(date_ranges, dimensions, metrics, page_token, filters = '')
        GetReportsRequest.new(
          report_requests: [ReportRequest.new(view_id: 'ga:' + config['view_id'].to_s,
                                              dimensions: dimensions,
                                              metrics: metrics,
                                              date_ranges: date_ranges,
                                              sort: 'ga:date',
                                              filters_expression: filters,
                                              page_size: PAGE_SIZE,
                                              page_token: page_token)]
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
