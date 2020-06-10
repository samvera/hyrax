# frozen_string_literal: true
module Hyrax
  module ProxyDeposit
    extend ActiveSupport::Concern

    included do
      property :proxy_depositor, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#proxyDepositor'), multiple: false do |index|
        index.as :symbol
      end

      # This value is set when a user indicates they are depositing this for someone else
      property :on_behalf_of, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#onBehalfOf'), multiple: false do |index|
        index.as :symbol
      end
    end

    def request_transfer_to(target)
      raise ArgumentError, "Must provide a target" unless target
      deposit_user = ::User.find_by_user_key(depositor)
      ProxyDepositRequest.create!(work_id: id, receiving_user: target, sending_user: deposit_user)
    end
  end
end
