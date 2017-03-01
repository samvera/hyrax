module Hyrax
  module Dashboard
    # Presenter for dashboard of a non-admin user
    class UserPresenter
      def initialize(current_user, view_context, since)
        @current_user = current_user
        @view_context = view_context
        @since = since
      end

      def activity
        @activity ||= current_user.all_user_activity(activity_seconds_ago)
      end

      def notifications
        @notifications ||= current_user.mailbox.inbox
      end

      def transfers
        @transfers ||= Hyrax::TransfersPresenter.new(current_user, view_context)
      end

      def render_recent_activity
        if activity.empty?
          t('hyrax.dashboard.no_activity')
        else
          render 'hyrax/users/activity_log', events: activity
        end
      end

      def render_recent_notifications
        if notifications.empty?
          t('hyrax.dashboard.no_notifications')
        else
          render "hyrax/notifications/notifications", messages: notifications_for_dashboard
        end
      end

      def link_to_additional_notifications
        return unless notifications.count > Hyrax.config.max_notifications_for_dashboard
        link_to t('hyrax.dashboard.additional_notifications'), hyrax.notifications_path
      end

      private

        attr_reader :current_user, :view_context, :since
        delegate :render, :t, :hyrax, :link_to, to: :view_context

        # @return [Integer] how long ago to query (in seconds)
        def activity_seconds_ago
          return since.to_i if since.present?
          DateTime.current.to_i - Hyrax.config.activity_to_show_default_seconds_since_now
        end

        def notifications_for_dashboard
          notifications.limit(Hyrax.config.max_notifications_for_dashboard)
        end
    end
  end
end
