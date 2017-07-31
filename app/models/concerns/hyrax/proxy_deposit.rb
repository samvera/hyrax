module Hyrax
  module ProxyDeposit
    extend ActiveSupport::Concern

    included do
      attribute :proxy_depositor, Valkyrie::Types::String
      # property :proxy_depositor, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#proxyDepositor'), multiple: false do |index|
      #   index.as :symbol
      # end

      attribute :on_behalf_of, Valkyrie::Types::String
      # # This value is set when a user indicates they are depositing this for someone else
      # property :on_behalf_of, predicate: ::RDF::URI.new('http://scholarsphere.psu.edu/ns#onBehalfOf'), multiple: false do |index|
      #   index.as :symbol
      # end

      # after_create :create_transfer_request
    end

    def create_transfer_request
      return if on_behalf_of.blank?
      ContentDepositorChangeEventJob.perform_later(self,
                                                   ::User.find_by_user_key(on_behalf_of))
    end

    def request_transfer_to(target)
      raise ArgumentError, "Must provide a target" unless target
      deposit_user = ::User.find_by_user_key(depositor)
      ProxyDepositRequest.create!(work_id: id, receiving_user: target, sending_user: deposit_user)
    end
  end
end
