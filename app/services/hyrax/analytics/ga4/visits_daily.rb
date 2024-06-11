# frozen_string_literal: true
module Hyrax
  module Analytics
    module Ga4
      class VisitsDaily < Hyrax::Analytics::Ga4::Base
        def initialize(start_date:, end_date:, dimensions: [{ name: 'date' }, { name: 'newVsReturning' }], metrics: [{ name: 'sessions' }])
          super
          @start_date = start_date.to_date
          @end_date = end_date.to_date
          @dimensions = dimensions
          @metrics = metrics
        end

        def new_visits
          results_array('new')
        end

        def return_visits
          results_array('returning')
        end

        def total_visits
          results_array
        end
      end
    end
  end
end
