# frozen_string_literal: true
module Hyrax
  module Analytics
    module Ga4
      class Events < Hyrax::Analytics::Ga4::Base
        def initialize(start_date:,
                       end_date:,
                       dimensions: [{ name: 'eventName' }, { name: 'contentType' }, { name: 'contentId' }],
                       metrics: [{ name: 'eventCount' }])
          super
        end

        def self.list(start_date, end_date, action)
          events = Events.new(start_date: start_date, end_date: end_date)
          events.add_filter(dimension: 'eventName', values: [action])
          events.top_result_array
        end

        def top_result_array
          results.map { |r| [unwrap_dimension(metric: r, dimension: 2), unwrap_metric(r)] }.sort_by { |r| r[1] }
        end
      end
    end
  end
end
