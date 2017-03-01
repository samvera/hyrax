module Hyrax
  module TransfersControllerBehavior
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_user!
      before_action :load_proxy_deposit_request, only: :create
      load_and_authorize_resource :proxy_deposit_request, parent: false, except: :index
      before_action :authorize_depositor_by_id, only: [:new, :create]
      # Catch permission errors
      # TODO: Isn't this already handled?
      rescue_from CanCan::AccessDenied do |exception|
        if current_user && current_user.persisted?
          redirect_to root_url, alert: exception.message
        else
          session["user_return_to"] = request.url
          redirect_to main_app.new_user_session_url, alert: exception.message
        end
      end
    end

    def new
      @work = Hyrax::WorkRelation.new.find(params[:id])
    end

    def create
      @proxy_deposit_request.sending_user = current_user
      if @proxy_deposit_request.save
        redirect_to hyrax.transfers_path, notice: "Transfer request created"
      else
        redirect_to root_url, alert: @proxy_deposit_request.errors.full_messages.to_sentence
      end
    end

    def index
      @presenter = TransfersPresenter.new(current_user, view_context)
    end

    # Kicks of a job that completes the transfer. If params[:reset] is set, it will revoke
    # any existing edit permissions on the work.
    def accept
      @proxy_deposit_request.transfer!(params[:reset])
      if params[:sticky]
        current_user.can_receive_deposits_from << @proxy_deposit_request.sending_user
      end
      redirect_to hyrax.transfers_path, notice: "Transfer complete"
    end

    def reject
      @proxy_deposit_request.reject!
      redirect_to hyrax.transfers_path, notice: "Transfer rejected"
    end

    def destroy
      @proxy_deposit_request.cancel!
      redirect_to hyrax.transfers_path, notice: "Transfer canceled"
    end

    private

      def authorize_depositor_by_id
        @id = params[:id]
        authorize! :transfer, @id
        @proxy_deposit_request.work_id = @id
      rescue CanCan::AccessDenied
        redirect_to root_url, alert: 'You are not authorized to transfer this work.'
      end

      def load_proxy_deposit_request
        @proxy_deposit_request = ProxyDepositRequest.new(proxy_deposit_request_params)
      end

      def proxy_deposit_request_params
        params.require(:proxy_deposit_request).permit(:transfer_to, :sender_comment)
      end
  end
end
