# frozen_string_literal: true
module Hyrax
  module Admin
    class RepositoryGrowthPresenter
      def initialize(start_date, end_date)
        @x_min = start_date
        @x_max = end_date
        @date_format = ->(x) { x.strftime('%F') }
      end

      def as_json(*)
        works.to_a.zip(collections.to_a).map do |e|
          { y: e.first.first, a: e.first.last, b: e.last.last }
        end
      end

      private

      def works
        Hyrax::Statistics::Works::OverTime.new(delta_x: 1,
                                               x_min: @x_min,
                                               x_max: @x_max,
                                               x_output: @date_format).points
      end

      def collections
        Hyrax::Statistics::Collections::OverTime.new(delta_x: 1,
                                                     x_min: @x_min,
                                                     x_max: @x_max,
                                                     x_output: @date_format).points
      end
    end
  end
end
