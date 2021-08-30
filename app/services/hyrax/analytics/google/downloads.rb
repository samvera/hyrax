# frozen_string_literal: true
module Hyrax
  module Analytics
    module Google
      module Downloads
        extend Legato::Model

        metrics :total_events
        dimensions :event_category, :event_action, :event_label

        filter(:file_set_download) { |_event_action| matches(:eventAction, 'file-set-download') }
        filter(:work_in_collection_download) { |_event_action| matches(:eventAction, 'work-in-collection-download') }
        filter(:file_set_in_work_download) { |_event_action| matches(:eventAction, 'file-set-in-work-download') }
        filter(:collection_file_download) { |_event_action| matches(:eventAction, 'file-set-in-collection-download') }
        filter :for_id, &->(id) { matches(:eventLabel, id) }

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

        def self.download_list(profile, start_date, end_date, ref)
          ref = ref.underscore
          results = []
          Downloads.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: ['-totalEvents']).send(ref).each do |result|
              results.push([result.eventLabel, result.totalEvents.to_i])
            end
          results
        end

        def self.results_array(response)
          results = []
          response.to_a.each do |result|
            results.push([result.date.to_date, result.totalEvents.to_i])
          end
          Hyrax::Analytics::Results.new(results)
        end
      end
    end
  end
end
