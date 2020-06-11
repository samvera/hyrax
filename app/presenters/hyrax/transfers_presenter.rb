# frozen_string_literal: true
module Hyrax
  class TransfersPresenter
    def initialize(current_user, view_context)
      @current_user = current_user
      @view_context = view_context
    end

    def render_sent_transfers
      if outgoing_proxy_deposits.present?
        render 'hyrax/transfers/sent', outgoing_proxy_deposits: outgoing_proxy_deposits
      else
        t('hyrax.dashboard.no_transfers')
      end
    end

    def render_received_transfers
      if incoming_proxy_deposits.present?
        render 'hyrax/transfers/received', incoming_proxy_deposits: incoming_proxy_deposits
      else
        t('hyrax.dashboard.no_transfer_requests')
      end
    end

    private

    attr_reader :current_user, :view_context, :since
    delegate :render, :t, to: :view_context

    def incoming_proxy_deposits
      @incoming ||= ProxyDepositRequest.incoming_for(user: current_user)
    end

    def outgoing_proxy_deposits
      @outgoing ||= ProxyDepositRequest.outgoing_for(user: current_user)
    end
  end
end
