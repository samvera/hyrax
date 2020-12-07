# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for deposit events, and checks for proxy situations. When a user
    # deposits an item `on_behalf_of` another, ensures transfer is handled.
    class ProxyDepositListener
      ##
      # @param event [Dry::Event]
      def on_object_deposited(event)
        return if event[:object].try(:on_behalf_of).blank? ||
                  (event[:object].on_behalf_of == event[:object].depositor)

        ContentDepositorChangeEventJob
          .perform_later(event[:object], ::User.find_by_user_key(event[:object].on_behalf_of))
      end
    end
  end
end
