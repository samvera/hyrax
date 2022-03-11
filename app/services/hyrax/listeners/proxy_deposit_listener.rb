# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for deposit events, and checks for proxy situations. When a user
    # deposits an item `on_behalf_of` another, logs the event.
    #
    # Former behavior of the ContentDepositorChangeEventJob was to actually
    # perform the transfer. That behavior is maintained for ActiveFedora code
    # paths. Moving forward the transfer is performed separately from this
    # listener and job, to avoid race conditions.
    class ProxyDepositListener
      ##
      # Called when 'object.deposited' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_deposited(event)
        return if event[:object].try(:on_behalf_of).blank? ||
                  (event[:object].on_behalf_of == event[:object].depositor)

        ContentDepositorChangeEventJob
          .perform_later(event[:object], ::User.find_by_user_key(event[:object].on_behalf_of))
      end
    end
  end
end
