# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # @deprecated transfer requests are now carried out synchronously during
    # object save
    #
    ## Listens for deposit events, and checks for proxy situations. When a user
    # deposits an item `on_behalf_of` another, ensures transfer is handled.
    class ProxyDepositListener
      ##
      # Called when 'object.deposited' event is published
      # @param [Dry::Events::Event] _event
      # @return [void]
      def on_object_deposited(_event)
        Deprecation.warn(
          "The ProxyDepositListener was deprecated, effective immediately, in \
          response to a difficult-to-diagnose race condition bug. This listener \
          is now a no-op. To retain functionality ensure that \
          DefaultMiddlewareStack is configured to use \
          Hyrax::Actors::TransferRequestActor and unregister this listener \
          in config/initializers/listeners.rb by adding the line: \n
          Hyrax.publisher.unsubscribe(Hyrax::Listeners::ProxyDepositListener.new)"
        )
      end
    end
  end
end
