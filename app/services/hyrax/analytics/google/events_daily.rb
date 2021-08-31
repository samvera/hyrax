# frozen_string_literal: true
module Hyrax
  module Analytics
    module Google
      module EventsDaily
        extend Legato::Model

        metrics :total_events
        dimensions :date, :event_category, :event_action

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

        # returns a daily number of events for a specific action
        def self.summary(profile, start_date, end_date, action)
          action = action.underscore
          response = EventsDaily.results(profile,
            start_date: start_date,
            end_date: end_date).send(action)
          dates = (start_date.to_date...end_date.to_date)
          results_array(response, dates)
        end

        # returns a daily number of events for a specific action
        def self.by_id(profile, start_date, end_date, id, action)
          action = action.underscore
          response = EventsDaily.results(profile,
            start_date: start_date,
            end_date: end_date).for_id(id).send(action)
          dates = (start_date.to_date...end_date.to_date)
          results_array(response, dates)
        end

        # def self.pageviews(profile, start_date, end_date, ref)
        #   ref = ref.underscore
        #   response = PageviewsDaily.results(profile,
        #     start_date: start_date,
        #     end_date: end_date).send(ref)
        #   dates = (start_date.to_date...end_date.to_date)
        #   results_array(response, dates)
        # end

        # takes all the dates in between the date range and generate an array [date, totalEvents]
        def self.results_array(response, dates)
          results = []
          response.to_a.each do |result|
            results.push([result.date.to_date, result.totalEvents.to_i])
          end
          new_results = []
          dates.each do |date|
            match = results.detect { |a, _b| a == date }
            if match
              new_results.push(match)
            else
              new_results.push([date, 0])
            end
          end
          Hyrax::Analytics::Results.new(new_results)
        end
      end
    end
  end
end
