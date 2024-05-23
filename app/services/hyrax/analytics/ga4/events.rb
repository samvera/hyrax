# frozen_string_literal: true
module Hyrax
  module Analytics
    module Ga4
      class Events < Hyrax::Analytics::Ga4::Base
        def initialize(start_date:,
          end_date:,
          dimensions: [{name: 'eventName'}, {name: 'contentType'}, {name: 'contentId'}],
          metrics: [{ name: 'eventCount' }]
        )
          @start_date = start_date.to_date
          @end_date = end_date.to_date
          @dimensions = dimensions
          @metrics = metrics
        end

        # dimensions :event_category, :event_action, :event_label

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
        def self.list(start_date, end_date, action)
          events = Events.new(start_date: start_date, end_date: end_date)
          events.add_filter(dimension: 'eventName', values: [action])
          events.top_result_array
        end
        # [id, total] sorted by total

        def top_result_array
          results.map { |r| [unwrap_dimension(metric: r, dimension: 2), unwrap_metric(r)]}.sort_by { |r| r[1] }
        end
      end
    end
  end
end
