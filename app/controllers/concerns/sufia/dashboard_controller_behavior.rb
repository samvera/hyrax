module Sufia
  module DashboardControllerBehavior
    extend ActiveSupport::Concern
    
    included do
      include ActionView::Helpers::DateHelper

      before_filter :authenticate_user!

      layout "sufia-dashboard"
    end

    # Render our dashboard page
    def index
      gather_dashboard_information
      respond_to do |format|
        format.html { }
        format.rss  { render layout: false }
        format.atom { render layout: false }
      end
    end

    # Returns a formated list of recent events in JSON for use with AJAX.
    def activity
      render json: human_readable_user_activity
    end

    protected

    # Gathers all the information that we'll display in the user's dashboard.
    # Override this method if you want to exclude or gather additional data elements
    # in your dashboard view.  You'll need to alter dashboard/index.html.erb accordingly.
    def gather_dashboard_information
      @user = current_user
      @activity = get_user_activity
      @notifications = current_user.mailbox.inbox
    end

    # Returns the most recent activity in the last 24 hours, or since a given timestamp
    # specified by params[:since]
    def get_user_activity
      since = params[:since] ? params[:since].to_i : (DateTime.now.to_i - 86400)
      current_user.events.reverse.collect { |event| event if event[:timestamp].to_i > since }.compact
    end

    # Formats the user's activities into human-readable strings used for rendering JSON
    def human_readable_user_activity
      get_user_activity.map do |event|
        [event[:action], "#{time_ago_in_words(Time.at(event[:timestamp].to_i))} ago", event[:timestamp].to_i]
      end
    end

  end
end
