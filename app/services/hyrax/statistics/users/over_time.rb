# frozen_string_literal: true
module Hyrax
  module Statistics
    module Users
      class OverTime < Statistics::OverTime
        # Overridden to do a noncumulative query
        def points
          Enumerator.new(size) do |y|
            x = @x_min
            while x <= @x_max
              y.yield [@x_output.call(x), point(x)]
              x += @delta_x.days
              y.yield [@x_output.call(x), point(bottom, x)]
            end
          end
        end

        private

        def relation
          ::User.registered
        end

        # Overridden to search one day at a time
        def query(date_string)
          { created_at: date_string.to_date.beginning_of_day..date_string.to_date.end_of_day }
        end

        def point(date_string)
          relation.where(query(date_string)).count
          puts "point >> #{point}"
          return point
        end
      end
    end
  end
end
