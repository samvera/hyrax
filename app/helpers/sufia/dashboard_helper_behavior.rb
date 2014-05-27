module Sufia
  module DashboardHelperBehavior

    def render_recent_activity
      if @activity.empty?
        "User has no recent activity"
      else
        render partial: 'users/activity_log', locals: {events: @activity}
      end
    end

    def render_recent_notifications
      if @notifications.empty?
        "User has no notifications"
      else
        render partial: "mailbox/notifications", locals: { messages: @notifications }
      end
    end

    def on_the_dashboard?
      params[:controller].match(/^dashboard|my/)
    end

  end
end
