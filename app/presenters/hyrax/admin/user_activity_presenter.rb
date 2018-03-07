module Hyrax
  module Admin
    class UserActivityPresenter
      def initialize
        @x_min = 90.days.ago.beginning_of_day
        @date_format = ->(x) { x.strftime('%b %-d') }
      end

      def as_json(*)
        new_users_list = { name: I18n.translate('hyrax.dashboard.show_admin.new_visitors'), data: [] }
        returning_users_list = { name: I18n.translate('hyrax.dashboard.show_admin.returning_visitors'), data: [] }

        new_users.to_a.zip(returning_users.to_a).map do |e|
          new_users_list[:data] << [e.first.first, e.first.last]

          visitor_count = if e.last.nil?
                            0
                          else
                            e.last
                          end

          returning_users_list[:data] << [e.first.first, visitor_count]
        end

        [new_users_list, returning_users_list]
      end

      private

        def new_users
          Hyrax::Statistics::Users::OverTime.new(x_min: @x_min,
                                                 x_output: @date_format).points
        end

        # TODO: using google analytics
        def returning_users
          []
        end
    end
  end
end
