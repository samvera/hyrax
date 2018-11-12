module Hyrax
  class DepositorsController < ApplicationController
    include DenyAccessOverrideBehavior

    before_action :authenticate_user!
    before_action :validate_users, only: :create

    layout :decide_layout

    def index
      add_breadcrumb t(:'hyrax.controls.home'), root_path
      add_breadcrumb t(:'hyrax.dashboard.breadcrumbs.admin'), hyrax.dashboard_path
      add_breadcrumb t(:'hyrax.dashboard.manage_proxies'), hyrax.depositors_path
      @user = current_user
    end

    def create
      grantor = authorize_and_return_grantor
      grantee = ::User.from_url_component(params[:grantee_id])
      if grantor.can_receive_deposits_from.include?(grantee)
        head :ok
      else
        grantor.can_receive_deposits_from << grantee
        send_proxy_depositor_added_messages(grantor, grantee)
        render json: { name: grantee.name, delete_path: hyrax.user_depositor_path(grantor.user_key, grantee.user_key) }
      end
    end

    def destroy
      grantor = authorize_and_return_grantor
      grantor.can_receive_deposits_from.delete(::User.from_url_component(params[:id]))
      head :ok
    end

    def validate_users
      head :ok if params[:user_id] == params[:grantee_id]
    end

    private

      def authorize_and_return_grantor
        grantor = ::User.from_url_component(params[:user_id])
        authorize! :edit, grantor
        grantor
      end

      def send_proxy_depositor_added_messages(grantor, grantee)
        message_to_grantee = I18n.t('hyrax.notifications.proxy_depositor_added.grantee_message', grantor: grantor.name)
        message_to_grantor = I18n.t('hyrax.notifications.proxy_depositor_added.grantor_message', grantee: grantee.name)
        Hyrax::MessengerService.deliver(::User.batch_user, grantor, message_to_grantor,
                                        I18n.t('hyrax.notifications.proxy_depositor_added.subject'))
        Hyrax::MessengerService.deliver(::User.batch_user, grantee, message_to_grantee,
                                        I18n.t('hyrax.notifications.proxy_depositor_added.subject'))
      end

      def decide_layout
        layout = case action_name
                 when 'index'
                   'dashboard'
                 else
                   '1_column'
                 end
        File.join(theme, layout)
      end
  end
end
