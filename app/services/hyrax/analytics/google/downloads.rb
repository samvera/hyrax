# frozen_string_literal: true
module Hyrax
  module Analytics
    module Google
      module Downloads
        extend Legato::Model

        metrics :total_events
        dimensions :date, :event_category, :event_action, :event_label
       
        filter(:downloads) { |_event_action| contains(:eventAction, 'Download') }
        filter(:works) { |_event_category| matches(:eventCategory, 'Works') }
        filter(:collections) { |_event_category| matches(:eventCategory, 'Collections') }

        filter(:collection_file_downloads) { |_event_action| matches(:eventAction, 'file-set-in-collection-download') }
        filter :for_id, &->(id) { contains(:eventLabel, id) }
        filter :for_file, &->(id) { contains(:eventLabel, file) }

        def self.results_array(response)
          results = []
          response.to_a.each do |result|
            results.push([result.date.to_date, result.totalEvents.to_i])
          end
          Hyrax::Analytics::Results.new(results)
        end

        def self.file_downloads(profile, start_date, end_date, file)
          results = Downloads.results(profile,
            start_date: start_date,
            end_date: end_date).for_file(file)
            if results.nil? || results.first.nil?
              0
            else
              results.first['totalEvents'].to_i
            end
        end

        def self.by_id(profile, start_date, end_date, id)
          response = Downloads.results(profile,
            start_date: start_date,
            end_date: end_date).for_id(id)
          results_array(response)
        end

        def self.by_collection_id(profile, start_date, end_date, id)
          response = Downloads.results(profile,
            start_date: start_date,
            end_date: end_date).collection_file_downloads.for_id(id)
          results_array(response)
        end

        def self.all(profile, start_date, end_date)
          response = Downloads.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").downloads
          results_array(response)
        end

        def self.collections(profile, start_date, end_date)
          response = Downloads.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").collections.downloads
          results_array(response)
        end

        def self.works(profile, start_date, end_date)
          response = Downloads.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").works.downloads
          results_array(response)
        end
      end
    end
  end
end
