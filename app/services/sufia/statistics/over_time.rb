module Sufia
  module Statistics
    # An abstract class for generating cumulative graphs
    # you must provide a `relation` method in the concrete class
    class OverTime
      # @param [Fixnum] delta_x change in x (in days)
      # @param [Time] x_min minimum date
      # @param [Time] x_max max date
      def initialize(delta_x: 7, x_min: 1.month.ago.beginning_of_day, x_max: Time.zone.now.end_of_day)
        @delta_x = delta_x
        @x_min = x_min
        @x_max = x_max
      end

      def points
        Enumerator.new(size) do |y|
          x = @x_min
          while x <= @x_max
            x += @delta_x.days
            y.yield [x.to_i * 1000, point(@x_min, x)]
          end
        end
      end

      private

        def point(min, max)
          relation.where(query(min, max)).count
        end

        def query(min, max)
          QueryService.new.build_date_query(min, max)
        end

        def size
          ((@x_max - @x_min) / @delta_x.days.to_i).ceil
        end

        def relation
          raise NotImplementedError, "Implement the relation method in a concrete class"
        end
    end
  end
end
