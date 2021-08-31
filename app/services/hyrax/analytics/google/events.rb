# frozen_string_literal: true
module Hyrax
  module Analytics
    module Google
      module Events
        extend Legato::Model

        metrics :total_events
        dimensions :event_category, :event_action, :event_label

        # Filter by event id
        filter :for_id, &->(id) { matches(:eventLabel, id) }

        # Filter by event action
        filter(:work_view) { |_event_action| matches(:eventAction, 'work-view') }
        filter(:work_in_collection_view) { |_event_action| matches(:eventAction, 'work-in-collection-view') }
        filter(:collection_page_view) { |_event_action| matches(:eventAction, 'collection-page-view') }
        filter(:file_set_download) { |_event_action| matches(:eventAction, 'file-set-download') }
        filter(:work_in_collection_download) { |_event_action| matches(:eventAction, 'work-in-collection-download') }
        filter(:file_set_in_work_download) { |_event_action| matches(:eventAction, 'file-set-in-work-download') }
        filter(:collection_file_download) { |_event_action| matches(:eventAction, 'file-set-in-collection-download') }

        def self.list(profile, start_date, end_date, action)
          action = action.underscore
          results = []
          Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: ['-totalEvents']).send(action).each do |result|
              results.push([result.eventLabel, result.totalEvents.to_i])
            end
          results
        end
      end
    end
  end
end
