# frozen_string_literal: true
module Hyrax
  module Analytics
    module Google
      module Downloads
        extend Legato::Model

        metrics :total_events
        dimensions :event_label

        def self.query(profile, start_date, end_date)
          x = Downloads.results(profile,
            start_date: start_date,
            end_date: end_date,
            sort: "-totalEvents",
            limit: 5)
        end
      end
    end
  end
end
