module Sufia
  module DashboardHelperBehavior
    def render_sent_transfers
      if @outgoing.present?
        render partial: 'transfers/sent'
      else
        t('sufia.dashboard.no_transfers')
      end
    end

    def render_received_transfers
      if @incoming.present?
        render partial: 'transfers/received'
      else
        t('sufia.dashboard.no_transfer_requests')
      end
    end

    def render_recent_activity
      if @activity.empty?
        t('sufia.dashboard.no_activity')
      else
        render partial: 'users/activity_log', locals: { events: @activity }
      end
    end

    def render_recent_notifications
      if @notifications.empty?
        t('sufia.dashboard.no_notifications')
      else
        render partial: "mailbox/notifications", locals: { messages: notifications_for_dashboard }
      end
    end

    def on_the_dashboard?
      params[:controller].match(/^dashboard|my/)
    end

    def on_my_works?
      params[:controller].match(/^my\/works/)
    end

    def number_of_works(user = current_user)
      ::GenericWork.where(Solrizer.solr_name('depositor', :symbol) => user.user_key).count
    end

    def number_of_files(user = current_user)
      ::FileSet.where(Solrizer.solr_name('depositor', :symbol) => user.user_key).count
    end

    def number_of_collections(user = current_user)
      ::Collection.where(Solrizer.solr_name('depositor', :symbol) => user.user_key).count
    end

    def notifications_for_dashboard
      @notifications.limit(Sufia.config.max_notifications_for_dashboard)
    end

    def link_to_additional_notifications
      return unless @notifications.count > Sufia.config.max_notifications_for_dashboard
      link_to t('sufia.dashboard.additional_notifications'), sufia.notifications_path
    end
  end
end
