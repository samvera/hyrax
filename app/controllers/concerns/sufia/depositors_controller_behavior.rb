module Sufia
  module DepositorsControllerBehavior
    extend ActiveSupport::Concern

    included do
      before_filter :authenticate_user!
      before_filter :validate_users, only: :create
    end


    # Overriding the default behavior from Hydra::Core::ContorllerBehavior
    def deny_access(exception)
      if current_user and current_user.persisted?
        redirect_to root_path, alert: exception.message
      else
        session['user_return_to'.freeze] = request.url
        redirect_to new_user_session_path, alert: exception.message
      end
    end

    def create
      grantor = authorize_and_return_grantor
      grantee = ::User.from_url_component(params[:grantee_id])
      if grantor.can_receive_deposits_from.include?(grantee)
        head :ok
      else
        grantor.can_receive_deposits_from << grantee
        render json: { name: grantee.name, delete_path: sufia.user_depositor_path(grantor.user_key, grantee.user_key) }
      end
    end

    def destroy
      grantor = authorize_and_return_grantor
      grantor.can_receive_deposits_from.delete(::User.from_url_component(params[:id]))
      head :ok
    end

    def validate_users
      if params[:user_id] == params[:grantee_id]
        head :ok
      end
    end

    private

    def authorize_and_return_grantor
      grantor = ::User.from_url_component(params[:user_id])
      authorize! :edit, grantor
      return grantor
    end
  end
end
