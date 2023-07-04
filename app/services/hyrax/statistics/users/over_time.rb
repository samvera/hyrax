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
          # convert the User::ActiveRecord_Relation to an array so that ".size" returns a number,
          # instead of a hash of { user_id: size }
          relation.where(query(date_string)).to_a.size
        end
      end
    end
  end
end
