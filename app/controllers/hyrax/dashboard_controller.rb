module Hyrax
  class DashboardController < ApplicationController
    include Blacklight::Base
    layout 'dashboard'
    before_action :authenticate_user!

    def show
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      if can? :read, :admin_dashboard
        @presenter = Hyrax::Admin::DashboardPresenter.new
        @admin_set_rows = Hyrax::AdminSetService.new(self).search_results_with_work_count(:read)
        render 'show_admin'
      else
        gather_dashboard_information
        render 'show_user'
      end
    end

    protected

      # Gathers all the information that we'll display in the user's dashboard.
      # Override this method if you want to exclude or gather additional data elements
      # in your dashboard view.  You'll need to alter dashboard/index.html.erb accordingly.
      def gather_dashboard_information
        @activity = current_user.all_user_activity(params[:since].blank? ? DateTime.current.to_i - Hyrax.config.activity_to_show_default_seconds_since_now : params[:since].to_i)
        @notifications = current_user.mailbox.inbox
        @incoming = ProxyDepositRequest.where(receiving_user_id: current_user.id).reject(&:deleted_work?)
        @outgoing = ProxyDepositRequest.where(sending_user_id: current_user.id)
      end
  end
end
