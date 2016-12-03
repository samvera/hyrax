module Hyrax
  module DepositorsControllerBehavior
    extend ActiveSupport::Concern
    include DenyAccessOverrideBehavior

    included do
      before_action :authenticate_user!
      before_action :validate_users, only: :create
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
        message_to_grantee = "#{grantor.name} has assigned you as a proxy depositor"
        message_to_grantor = "You have assigned #{grantee.name} as a proxy depositor"
        ::User.batch_user.send_message(grantor, message_to_grantor, "Proxy Depositor Added")
        ::User.batch_user.send_message(grantee, message_to_grantee, "Proxy Depositor Added")
      end
  end
end
