# frozen_string_literal: true
module Hyrax
  module Statistics
    # An abstract class for generating cumulative graphs
    # you must provide a `relation` method in the concrete class
    class OverTime
      # @param [Fixnum] delta_x change in x (in days)
      # @param [Time] x_min minimum date
      # @param [Time] x_max max date
      # @param [Lambda] x_output a lambda for converting x to the desired output value.
      #                 defaults to milliseconds since the epoch
      def initialize(delta_x: 7,
                     x_min: 1.month.ago.beginning_of_day,
                     x_max: Time.zone.now.end_of_day,
                     x_output: ->(x) { x.to_i * 1000 })
        @delta_x = delta_x
        @x_min = x_min
        @x_max = x_max
        @x_output = x_output
      end

      def points
        Enumerator.new(size) do |y|
          x = @x_min
          while x <= @x_max
            x += @delta_x.days
            y.yield [@x_output.call(x), point(@x_min, x)]
          end
        end
      end

      private

      def point(min, max)
        relation.where(query(min, max)).count
      end

      def query(min, max)
        query_service.build_date_query(min, max)
      end

      def query_service
        Hyrax::Statistics::ValkyrieQueryService.new
      end

      # How many points are in this data set
      def size
        ((@x_max - @x_min) / @delta_x.days.to_i).ceil
      end

      def relation
        raise NotImplementedError, "Implement the relation method in a concrete class"
      end
    end
  end
end
