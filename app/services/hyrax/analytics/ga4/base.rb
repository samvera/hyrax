# frozen_string_literal: true
module Hyrax
  module Analytics
    module Ga4
      class Base
        attr_reader :start_date, :end_date, :dimensions, :metrics

        def initialize(start_date:,
                       end_date:,
                       dimensions: [],
                       metrics: [])
          @start_date = start_date.to_date
          @end_date = end_date.to_date
          @dimensions = dimensions
          @metrics = metrics
        end

        def filters
          @filters ||= {}
        end

        def filters=(value)
          value
        end

        def add_filter(dimension:, values:)
          # reset any cached results
          @results = nil
          filters[dimension] ||= []
          filters[dimension] += values
        end

        def results
          @results ||= Hyrax::Analytics.client.run_report(report).rows
        end

        def report
          ::Google::Analytics::Data::V1beta::RunReportRequest.new(
            property: Hyrax::Analytics.property,
            metrics: metrics,
            date_ranges: [{ start_date: start_date.iso8601, end_date: end_date.iso8601 }],
            dimensions: dimensions,
            dimension_filter: dimension_filter
          )
        end

        def dimension_filter
          return nil if filters.blank?
          {
            and_group: {
              expressions: dimension_expressions
            }
          }
        end

        def dimension_expressions
          filters.map do |dimension, values|
            {
              filter: {
                field_name: dimension,
                in_list_filter: { values: values.uniq }
              }
            }
          end
        end

        def results_array(target_type = nil)
          r = {}
          # prefill dates so that all dates at least have 0
          (start_date..end_date).each do |date|
            r[date] = 0
          end
          results.each do |result|
            date = unwrap_dimension(metric: result, dimension: 0)
            type = unwrap_dimension(metric: result, dimension: 1)
            next if date.nil? || type.nil?
            next if target_type && type != target_type
            date = date.to_date
            r[date] += unwrap_metric(result)
          end
          Hyrax::Analytics::Results.new(r.to_a)
        end

        protected

        def unwrap_dimension(metric:, dimension: 0)
          metric.dimension_values[dimension]&.value
        end

        def unwrap_metric(metric)
          metric.metric_values.first.value.to_i
        end
      end
    end
  end
end
