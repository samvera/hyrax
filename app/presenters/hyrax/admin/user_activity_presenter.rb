module Hyrax
  module Admin
    class UserActivityPresenter
      def initialize
        @x_min = 90.days.ago.beginning_of_day
        @date_format = ->(x) { x.strftime('%b %-d') }
      end

      def as_json(*)
        visitors_list = { name: I18n.translate('hyrax.dashboard.show_admin.visitors'), data: visitors.to_a }
        sessions_list = { name: I18n.translate('hyrax.dashboard.show_admin.sessions'), data: sessions.to_a }

        [visitors_list, sessions_list]
      end

      private

        def visitors
          Hyrax::Statistics::Site::Visitors.new(x_min: @x_min,
                                                x_output: @date_format).points
        end

        def sessions
          Hyrax::Statistics::Site::Sessions.new(x_min: @x_min,
                                                x_output: @date_format).points
        end
    end
  end
end
