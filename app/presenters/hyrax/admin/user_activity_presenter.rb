# frozen_string_literal: true
module Hyrax
  module Admin
    class UserActivityPresenter
      def initialize(start_date, end_date)
        @x_min = start_date
        @x_max = end_date
        @date_format = ->(x) { x }
      end

      def as_json(*)
        new_users.to_a
      end

      private

      def new_users
        Hyrax::Statistics::Users::OverTime.new(delta_x: 1,
                                               x_min: @x_min,
                                               x_max: @x_max,
                                               x_output: @date_format).points
      end
    end
  end
end
