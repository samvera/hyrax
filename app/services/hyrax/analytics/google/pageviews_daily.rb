# frozen_string_literal: true
module Hyrax
  module Analytics
    module Google
      module PageviewsDaily
        extend Legato::Model

        metrics :total_events
        dimensions :date, :event_category, :event_action

        filter(:work_view) { |_event_action| matches(:eventAction, 'work-view') }
        filter(:work_in_collection_view) { |_event_action| matches(:eventAction, 'work-in-collection-view') }
        filter(:collection_page_view) { |_event_action| matches(:eventAction, 'collection-page-view') }
        filter :for_id, &->(id) { contains(:eventLabel, id) }

        # returns a daily number of views for a specific work
        def self.by_id(profile, start_date, end_date, id)
          response = PageviewsDaily.results(profile,
            start_date: start_date,
            end_date: end_date).for_id(id).work_view
          dates = (start_date.to_date...end_date.to_date)
          results_array(response, dates)
        end

        def self.pageviews(profile, start_date, end_date, ref)
          ref = ref.underscore
          response = PageviewsDaily.results(profile,
            start_date: start_date,
            end_date: end_date).send(ref)
          dates = (start_date.to_date...end_date.to_date)
          results_array(response, dates)
        end

        # takes all the dates in between date range and generates an array [date, totalEvents]
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
