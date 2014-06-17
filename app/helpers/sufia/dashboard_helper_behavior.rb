module Sufia
  module DashboardHelperBehavior

    def render_recent_activity
      if @activity.empty?
        t('sufia.dashboard.no_activity')
      else
        render partial: 'users/activity_log', locals: {events: @activity}
      end
    end

    def render_recent_notifications
      if @notifications.empty?
        t('sufia.dashboard.no_notifications')
      else
        render partial: "mailbox/notifications", locals: { messages: @notifications }
      end
    end

    def on_the_dashboard?
      params[:controller].match(/^dashboard|my/)
    end

    def number_of_files user=current_user
      ::GenericFile.where(Solrizer.solr_name('depositor', :stored_searchable) => user.user_key).count
    end

    def number_of_collections user=current_user
      Collection.where(Solrizer.solr_name('depositor', :stored_searchable) => user.user_key).count
    end

  end
end
