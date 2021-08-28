# frozen_string_literal: true
module Hyrax
  module Analytics
    module Google
      module EventsDaily
        extend Legato::Model

        metrics :total_events
        dimensions :date, :event_category, :event_action
        
        filter(:works_views) { |_event_action| matches(:eventAction, 'work-view') }
        filter(:work_in_collection_views) { |_event_action| matches(:eventAction, 'work-in-collection-view') }
        filter(:collection_page_views) { |_event_action| matches(:eventAction, 'collection-page-view') }
        filter(:collection_downloads) { |_event_action| matches(:eventAction, 'file-set-in-collection-download') }
        filter(:work_in_collection_downloads) { |_event_action| matches(:eventAction, 'work-in-collection-download') }
        filter(:file_set_downloads) { |_event_action| matches(:eventAction, 'file-set-downloads') }

        filter(:downloads) { |_event_action| matches(:eventAction, 'Downloads') }
        filter(:files) { |_event_category| matches(:eventCategory, 'Files') }
        filter(:downloaded) { |_event_action| matches(:eventAction, 'Downloaded') }
        filter(:works) { |_event_category| matches(:eventCategory, 'Works') }
        filter(:collections) { |_event_category| matches(:eventCategory, 'Collections') }
        filter(:views) { |_event_action| contains(:eventAction, 'Views') }
        filter :for_file, &->(file) { contains(:eventLabel, file) }

        # def self.downloads(profile, start_date, end_date)
        #   response = EventsDaily.results(profile,
        #     start_date: start_date,
        #     end_date: end_date,
        #     sort: "date").downloads
        #   dates = (start_date.to_date...end_date.to_date)
        #   results_array(response, dates)
        # end
 
        def self.collection_page_views(profile, start_date, end_date)
          response = EventsDaily.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "date").collection_page_views
          dates = (start_date.to_date...end_date.to_date)
          results_array(response, dates)
        end

        def self.work_in_collection_views(profile, start_date, end_date)
          response = EventsDaily.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "date").work_in_collection_views
          dates = (start_date.to_date...end_date.to_date)
          results_array(response, dates)
        end

        def self.works_views(profile, start_date, end_date)
          response = EventsDaily.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "date").works_views
          dates = (start_date.to_date...end_date.to_date)
          results_array(response, dates)
        end

        def self.works_downloads(profile, start_date, end_date)
          response = EventsDaily.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "date").works.downloads
          dates = (start_date.to_date...end_date.to_date)
          results_array(response, dates)
        end

        def self.collections_downloads(profile, start_date, end_date)
          response = EventsDaily.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "date").collection_downloads
          dates = (start_date.to_date...end_date.to_date)
          results_array(response, dates)
        end

        def self.work_in_collection_downloads(profile, start_date, end_date)
          response = EventsDaily.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "date").work_in_collection_downloads
          dates = (start_date.to_date...end_date.to_date)
          results_array(response, dates)
        end

        def self.file_set_downloads(profile, start_date, end_date)
          response = EventsDaily.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "date").file_set_downloads
          dates = (start_date.to_date...end_date.to_date)
          results_array(response, dates)
        end

        # def self.files_downloads(profile, start_date, end_date)
        #   response = EventsDaily.results(profile,
        #     start_date: start_date,
        #     end_date: end_date,
        #     sort: "date").files.downloaded
        #   dates = (start_date.to_date...end_date.to_date)
        #   results_array(response, dates)
        # end

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
          Hyrax::Analytics::Results.new(new_results.reverse)
        end

      end
    end
  end
end