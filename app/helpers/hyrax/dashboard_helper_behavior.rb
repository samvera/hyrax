module Hyrax
  module DashboardHelperBehavior
    def render_sent_transfers
      if @outgoing.present?
        render 'hyrax/transfers/sent'
      else
        t('hyrax.dashboard.no_transfers')
      end
    end

    def render_received_transfers
      if @incoming.present?
        render 'hyrax/transfers/received'
      else
        t('hyrax.dashboard.no_transfer_requests')
      end
    end

    def render_recent_activity
      if @activity.empty?
        t('hyrax.dashboard.no_activity')
      else
        render 'hyrax/users/activity_log', events: @activity
      end
    end

    def render_recent_notifications
      if @notifications.empty?
        t('hyrax.dashboard.no_notifications')
      else
        render "hyrax/notifications/notifications", messages: notifications_for_dashboard
      end
    end

    def on_the_dashboard?
      params[:controller].match(%r{^hyrax/dashboard|hyrax/my})
    end

    def on_my_works?
      params[:controller].match(%r{^hyrax/my/works})
    end

    def number_of_works(user = current_user)
      Hyrax::WorkRelation.new.where(DepositSearchBuilder.depositor_field => user.user_key).count
    rescue RSolr::Error::ConnectionRefused
      'n/a'
    end

    def number_of_files(user = current_user)
      ::FileSet.where(DepositSearchBuilder.depositor_field => user.user_key).count
    rescue RSolr::Error::ConnectionRefused
      'n/a'
    end

    def number_of_collections(user = current_user)
      ::Collection.where(DepositSearchBuilder.depositor_field => user.user_key).count
    rescue RSolr::Error::ConnectionRefused
      'n/a'
    end

    def notifications_for_dashboard
      @notifications.limit(Hyrax.config.max_notifications_for_dashboard)
    end

    def link_to_additional_notifications
      return unless @notifications.count > Hyrax.config.max_notifications_for_dashboard
      link_to t('hyrax.dashboard.additional_notifications'), hyrax.notifications_path
    end
  end
end
