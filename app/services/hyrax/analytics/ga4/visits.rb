# frozen_string_literal: true
module Hyrax
  module Analytics
    module Ga4
      class Visits < Hyrax::Analytics::Ga4::Base
        def initialize(start_date:, end_date:, dimensions: [{ name: 'newVsReturning' }], metrics: [{ name: 'sessions' }])
          super
        end

        def new_visits
          unwrap_metric(results.detect { |r| unwrap_dimension(metric: r) == 'new' })
        end

        def return_visits
          unwrap_metric(results.detect { |r| unwrap_dimension(metric: r) == 'returning' })
        end

        def unknown_visits
          empty_metrics = results.detect { |r| unwrap_dimension(metric: r) == '' }
          not_set_metrics = results.detect { |r| unwrap_dimension(metric: r) == '(not set)' }
          unknown = 0
          unknown += unwrap_metric(empty_metrics) if empty_metrics.present?
          unknown += unwrap_metric(not_set_metrics) if not_set_metrics.present?
          unknown
        end

        def total_visits
          new_visits + return_visits + unknown_visits
        end
      end
    end
  end
end
