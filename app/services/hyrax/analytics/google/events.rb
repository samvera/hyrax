# frozen_string_literal: true
module Hyrax
  module Analytics
    module Google
      module Events
        extend Legato::Model

        metrics :total_events
        dimensions :date, :event_category, :event_action, :event_label

        filter(:downloads) { |_event_category| contains(:eventAction, 'Download') }
        filter(:works) { |_event_category| matches(:eventCategory, 'Works') }
        filter(:collections) { |_event_category| matches(:eventCategory, 'Collections') }
        filter(:views) { |_event_action| contains(:eventAction, 'Views') }
        filter :for_file, &->(file) { contains(:eventLabel, file) }

        def self.results_array(response)
          results = []
          response.to_a.each do |result|
            results.push([result.eventLabel, result.totalEvents.to_i])
          end
          results
        end

        def self.downloads(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").downloads
          results_array(response)
        end

        def self.collections(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").collections.views
          results_array(response)
        end

        def self.works(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").works.views
          results_array(response)
        end

        def self.works_downloads(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").works.downloads
          results_array(response)
        end

        def self.collections_downloads(profile, start_date, end_date)
          response = Events.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents").collections.downloads
          results_array(response)
        end
      end
    end
  end
end
