# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for deposit events, and checks for proxy situations. When a user
    # deposits an item `on_behalf_of` another, performs the transfer and logs
    # the event.
    #
    # This listener is no longer used for Valkyrie-based workflows. Instead, the
    # ChangeContentDepositorService and ContentDepositorChangeEventJob are
    # invoked directly. This avoids observed race conditions.
    class ProxyDepositListener
      ##
      # Called when 'object.deposited' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_deposited(event)
        return if event[:object].is_a? Valyrie::Resource
        return if event[:object].try(:on_behalf_of).blank? ||
                  (event[:object].on_behalf_of == event[:object].depositor)

        obj = even[:object], user = ::User.find_by_user_key(event[:object].on_behalf_of)
        Hyrax::ChangeContentDepositorService.call(obj, user, false)
        ContentDepositorChangeEventJob.perform_later(obj, user))
      end
    end
  end
end
