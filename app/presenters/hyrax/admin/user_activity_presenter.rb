module Hyrax
  module Admin
    class UserActivityPresenter
      def initialize
        @x_min = 90.days.ago.beginning_of_day
        @date_format = ->(x) { x.strftime('%b %-d') }
      end

      def as_json(*)
        unique_visitors_list = { name: I18n.translate('hyrax.dashboard.show_admin.new_visitors'), data: unique_visitors.to_a }
        returning_visitors_list = { name: I18n.translate('hyrax.dashboard.show_admin.returning_visitors'), data: returning_visitors.to_a }

        [unique_visitors_list, returning_visitors_list]
      end

      private

        def unique_visitors
          Hyrax::Statistics::Site::UniqueVisitors.new(x_min: @x_min,
                                                      x_output: @date_format).points
        end

        def returning_visitors
          Hyrax::Statistics::Site::ReturningVisitors.new(x_min: @x_min,
                                                         x_output: @date_format).points
        end
    end
  end
end
