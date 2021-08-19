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
        new_users.to_a.zip(returning_users.to_a).map do |e|
          { y: e.first.first, a: e.first.last, b: e.last.try(:last) }
        end
      end

      private

      def new_users
        Hyrax::Statistics::Users::OverTime.new(x_min: @x_min,
                                               x_max: @x_max,
                                               x_output: @date_format).points
      end

      # TODO: using google analytics
      def returning_users
        []
      end
    end
  end
end
