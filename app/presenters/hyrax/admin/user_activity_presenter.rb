# frozen_string_literal: true
module Hyrax
  module Admin
    class UserActivityPresenter
      def initialize(start_date, end_date)
        @x_min = start_date
        @x_max = end_date
        @date_format = ->(x) { x.strftime('%b %-d') }
      end

      def as_json(*)
        new_users.to_a.zip(
                    returning_users.to_a,
                    new_visitors.to_a,
                    returning_visitors.to_a,
                    total_visitors.to_a
                  )
                 .map do |e|
          {
            y: e.first.first,
            new_users: e.first.last,
            returning_users: e.second.try(:last),
            new_visitors: e.third,
            returning_visitors: e.fourth,
            total_visitors: e.fifth
          }
        end
      end

      private

      def new_users
        Hyrax::Statistics::Users::OverTime.new(delta_x: 1,
                                               x_min: @x_min,
                                               x_max: @x_max,
                                               x_output: @date_format).points
      end

      # TODO: using google analytics
      def returning_users
        []
      end
      def new_visitors
        visitors_array = []
        x = @x_min
        while x <= @x_max
          visitor_count = Hyrax::Analytics.new_visitors('day', x)
          visitors_array << visitor_count
          x += 1.day
        end

        visitors_array
      end

      def returning_visitors
        visitors_array = []
        x = @x_min
        while x <= @x_max
          visitor_count = Hyrax::Analytics.returning_visitors('day', x)
          visitors_array << visitor_count
          x += 1.day
        end

        visitors_array
      end

      def total_visitors
        visitors_array = []
        x = @x_min
        while x <= @x_max
          visitor_count = Hyrax::Analytics.new_visitors('day', x)
          visitors_array << visitor_count
          x += 1.day
        end

        visitors_array
      end
    end
  end
end
