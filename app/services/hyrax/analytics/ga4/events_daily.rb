# frozen_string_literal: true
module Hyrax
  module Analytics
    module Ga4
      class EventsDaily < Hyrax::Analytics::Ga4::Base
        def initialize(start_date:,
            end_date:,
            dimensions: [{name: 'date'}, {name: 'eventName'}, {name: 'contentType'}, {name: 'contentId'}],
            metrics: [{ name: 'eventCount' }]
          )
            @start_date = start_date.to_date
            @end_date = end_date.to_date
            @dimensions = dimensions
            @metrics = metrics
          end


        # # Filter by event id
        # filter :for_id, &->(id) { matches(:eventLabel, id) }

        # # Filter by event action
        # filter(:work_view) { |_event_action| matches(:eventAction, 'work-view') }
        # filter(:work_in_collection_view) { |_event_action| matches(:eventAction, 'work-in-collection-view') }
        # filter(:collection_page_view) { |_event_action| matches(:eventAction, 'collection-page-view') }
        # filter(:file_set_download) { |_event_action| matches(:eventAction, 'file-set-download') }
        # filter(:work_in_collection_download) { |_event_action| matches(:eventAction, 'work-in-collection-download') }
        # filter(:file_set_in_work_download) { |_event_action| matches(:eventAction, 'file-set-in-work-download') }
        # filter(:collection_file_download) { |_event_action| matches(:eventAction, 'file-set-in-collection-download') }

        # returns a daily number of events for a specific action
        def self.summary(start_date, end_date, action)
          events_daily = EventsDaily.new(
            start_date: start_date,
            end_date: end_date)
          events_daily.add_filter(dimension: 'eventName', values: [action])
          events_daily.results_array
        end

        # returns a daily number of events for a specific action
        def self.by_id(start_date, end_date, id, action)
          events_daily = EventsDaily.new(
            start_date: start_date,
            end_date: end_date)
          events_daily.add_filter(dimension: 'contentId', values: [id])
          events_daily.add_filter(dimension: 'eventName', values: [action])
          events_daily.results_array
        end
      end
    end
  end
end
