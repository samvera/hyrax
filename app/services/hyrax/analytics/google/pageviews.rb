# frozen_string_literal: true
module Hyrax
  module Analytics
    module Google
      module Pageviews
        extend Legato::Model

        metrics :total_events
        dimensions :event_category, :event_action, :event_label

        filter(:work_view) { |_event_action| matches(:eventAction, 'work-view') }
        filter(:work_in_collection_view) { |_event_action| matches(:eventAction, 'work-in-collection-view') }
        filter(:collection_page_view) { |_event_action| matches(:eventAction, 'collection-page-view') }
        filter :for_id, &->(id) { contains(:eventLabel, id) }

        def self.by_id(profile, start_date, end_date, id)
          response = Pageviews.results(profile,
            start_date: start_date,
            end_date: end_date).for_id(id).work_views
          results_array(response)
        end

        def self.page_list(profile, start_date, end_date, ref)
          ref = ref.underscore
          results = []
          Pageviews.results(profile,
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
            results.push([result.eventLabel, result.totalEvents.to_i])
          end
          Hyrax::Analytics::Results.new(results)
        end
      end
    end
  end
end
