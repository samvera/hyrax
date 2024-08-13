# frozen_string_literal: true
module Hyrax
  module Analytics
    module Ga4
      class EventsDaily < Hyrax::Analytics::Ga4::Base
        def initialize(start_date:,
                       end_date:,
                       dimensions: [{ name: 'date' }, { name: 'eventName' }, { name: 'contentType' }, { name: 'contentId' }],
                       metrics: [{ name: 'eventCount' }])
          super
        end

        # returns a daily number of events for a specific action
        def self.summary(start_date, end_date, action)
          events_daily = EventsDaily.new(
            start_date: start_date,
            end_date: end_date
          )
          events_daily.add_filter(dimension: 'eventName', values: [action])
          events_daily.results_array
        end

        # returns a daily number of events for a specific action
        def self.by_id(start_date, end_date, id, action)
          events_daily = EventsDaily.new(
            start_date: start_date,
            end_date: end_date
          )
          events_daily.add_filter(dimension: 'contentId', values: [id])
          events_daily.add_filter(dimension: 'eventName', values: [action])
          events_daily.results_array
        end
      end
    end
  end
end
