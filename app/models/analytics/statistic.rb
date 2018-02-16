require 'google/apis/analyticsreporting_v4'
include Google::Apis::AnalyticsreportingV4

module Analytics
  class Statistic < ActiveRecord::Base
    self.abstract_class = true

    class_attribute :cache_column, :event_type

    class << self
      include Rails.application.routes.url_helpers

      def statistics_for(object)
        where(filter(object))
      end

      def build_for(object, attrs)
        new attrs.merge(filter(object))
      end

      def convert_date(date_time)
        date_time.to_datetime.to_i * 1000
      end

      def statistics(object, start_date, user_id = nil)
        combined_stats object, start_date, cache_column, event_type, user_id
      end

      def ga_statistics(start_date, object)
        reporting_service, view_id = Hyrax::Analytics.profile
        # reporting_service = profile[:reporting_service]
        unless reporting_service
          Rails.logger.error("Google Analytics Reporting Service has not been established. Unable to fetch statistics.")
          return []
        end

        date_ranges = [DateRange.new(start_date: start_date, end_date: 'today')]
        dimensions = dimension_terms.map { |d| Dimension.new(name: 'ga:' + d) }
        metrics = metric_terms.map { |m| Metric.new(expression: 'ga:' + m) }

        request = ga_report_request(object, view_id, date_ranges, dimensions, metrics)
        response = reporting_service.batch_get_reports(request)
        return [] if response.try(:reports).try(:first).try(:data).try(:rows).blank?
        ga_stats_rows(response)
      end

      # override metrics_terms, dimensions_terms and filters to provide specific GA query parameters
      # these defaults work for pageviews by date, filtered by "pagePath contains object path"
      def dimension_terms
        ['date']
      end

      def metric_terms
        ['pageviews']
      end

      def filters(object)
        'ga:pagePath=~' + polymorphic_path(object)
      end

      private

        def ga_report_request(object, view_id, date_ranges, dimensions, metrics)
          GetReportsRequest.new(
            report_requests: [ReportRequest.new(view_id: view_id,
                                                dimensions: dimensions,
                                                metrics: metrics,
                                                date_ranges: date_ranges,
                                                sort: 'ga:date',
                                                filters_expression: filters(object))]
          )
        end

        def ga_stats_rows(response)
          output = []
          response.reports.first.data.rows.each do |row|
            output_row = OpenStruct.new
            output << ga_openstruct_row(row.to_h, output_row)
          end
          output
        end

        def ga_openstruct_row(row, output_row)
          Rails.logger.error 'Hyrax::Statistic.ga_statistics - Bad Google Analytics data' if row[:dimensions].blank? || row[:metrics].blank?
          dimension_terms.zip(row[:dimensions]).each do |term, value|
            output_row[term] = value
          end
          metric_terms.zip(row[:metrics].first[:values]).each do |term, value|
            output_row[term] = value
          end
          output_row
        end

        def cached_stats(object, start_date, _method)
          stats = statistics_for(object).order(date: :asc)
          ga_start_date = stats.any? ? Date.parse(stats[stats.size - 1].date.strftime('%Y-%m-%d')) + 1.day : start_date.to_date
          { ga_start_date: ga_start_date, cached_stats: stats.to_a }
        end

        def combined_stats(object, start_date, object_method, ga_key, user_id = nil)
          stat_cache_info = cached_stats(object, start_date, object_method)
          stats = stat_cache_info[:cached_stats]
          if stat_cache_info[:ga_start_date] < Time.zone.today
            ga_stats = ga_statistics(stat_cache_info[:ga_start_date], object)
            ga_stats.each do |stat|
              lstat = build_for(object, date: stat[:date], object_method => stat[ga_key], user_id: user_id)
              lstat.save unless Date.parse(stat[:date]) == Time.zone.today
              stats << lstat
            end
          end
          stats
        end
      end

    def to_flot
      [self.class.convert_date(date), send(cache_column)]
    end
  end
end
