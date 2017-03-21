module Hyrax
  module DashboardControllerBehavior
    extend ActiveSupport::Concern

    included do
      include ActionView::Helpers::DateHelper

      before_action :authenticate_user!
    end

    # Render our dashboard page
    def index
      gather_dashboard_information
      respond_to do |format|
        format.html {}
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
      # @todo Consolidate these 5 instance variables into a presenter object for the Dashboard
      def gather_dashboard_information
        @user = current_user
        @activity = current_user.all_user_activity(params[:since].blank? ? DateTime.current.to_i - Hyrax.config.activity_to_show_default_seconds_since_now : params[:since].to_i)
        @notifications = current_user.mailbox.inbox
        @incoming = ProxyDepositRequest.incoming_for(user: current_user)
        @outgoing = ProxyDepositRequest.outgoing_for(user: current_user)
      end

      # Formats the user's activities into human-readable strings used for rendering JSON
      def human_readable_user_activity
        current_user.all_user_activity.map do |event|
          [event[:action], "#{time_ago_in_words(Time.zone.at(event[:timestamp].to_i))} ago", event[:timestamp].to_i]
        end
      end
  end
end
