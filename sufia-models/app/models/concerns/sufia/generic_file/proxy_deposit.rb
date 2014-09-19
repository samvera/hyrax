module Sufia
  module GenericFile
    module ProxyDeposit
      extend ActiveSupport::Concern

      included do
        has_attributes :proxy_depositor, :on_behalf_of, datastream: :properties, multiple: false
        after_create :create_transfer_request
      end

      def create_transfer_request
        Sufia.queue.push(ContentDepositorChangeEventJob.new(pid, on_behalf_of)) if on_behalf_of.present?
      end

      def request_transfer_to(target)
        raise ArgumentError, "Must provide a target" unless target
        deposit_user = ::User.find_by_user_key(depositor)
        ProxyDepositRequest.create!(pid: pid, receiving_user: target, sending_user: deposit_user)
      end
    end
  end
end
