# frozen_string_literal: true
module Hyrax
  module Analytics
    module Google
      module Events
        extend Legato::Model

        metrics :total_events
        dimensions :event_category, :event_action, :event_label

        filter(:work_views) { |_event_action| matches(:eventAction, 'work-view') }
        filter(:file_set_downloads) { |_event_action| matches(:eventAction, 'file-set-download') }
        filter(:work_in_collection_views) { |_event_action| matches(:eventAction, 'work-in-collection-view') }
        filter(:collection_page_views) { |_event_action| matches(:eventAction, 'collection-page-view') }
        filter(:file_set_in_work_downloads) { |_event_action| matches(:eventAction, 'file-set-in-work-downloads') }
        filter(:work_in_collection_downloads) { |_event_action| matches(:eventAction, 'work-in-collection-download') }
        
        filter(:download) { |_event_action| matches(:eventAction, 'Download') }
        filter(:downloads) { |_event_action| matches(:eventAction, 'Downloads') }
        filter(:downloaded) { |_event_action| matches(:eventAction, 'Downloaded') }
        filter(:files) { |_event_category| matches(:eventCategory, 'Files') }
        filter(:works) { |_event_category| matches(:eventCategory, 'Works') }
        filter(:collections) { |_event_category| matches(:eventCategory, 'Collections') }
        filter(:views) { |_event_action| contains(:eventAction, 'Views') }
        filter :for_file, &->(file) { contains(:eventLabel, file) }

        def self.results_array(response)
          results = []
          response.to_a.each do |result|
            results.push([result.eventLabel, result.totalEvents.to_i])
          end
          Hyrax::Analytics::Results.new(results)
        end

        def self.work_in_collection_downloads(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").work_in_collection_downloads
          results_array(response)
        end
        
        def self.downloads(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").download
          results_array(response)
        end

        def self.collections(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").collections.views
          results_array(response)
        end

        def self.work_in_collection_views(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").work_in_collection_views
          results_array(response)
        end

        def self.collection_page_views(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").collection_page_views
          results_array(response)
        end
        
        def self.works(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").work_views
          results_array(response)
        end      

        def self.works_views(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").work_views
          results_array(response)
        end   

        def self.works_downloads(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").works.downloads.each 
          results_array(response)
        end

        def self.collections_downloads(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").collections.downloads
          results_array(response)
        end

        def self.file_set_downloads(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").file_set_downloads
           results_array(response)
        end

        def self.file_set_in_work_downloads(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").file_set_in_work_downloads
           results_array(response)
        end

      end
    end
  end
end
