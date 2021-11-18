# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for events related to batch activity and creates notifications
    class BatchNotificationListener
      ##
      # Notify requesting users of batch success/failure
      #
      # Called when 'batch.created' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_batch_created(event)
        case event[:result]
        when :success
          Hyrax::BatchCreateSuccessService
            .new(event[:user])
            .call
        when :failure
          Hyrax::BatchCreateFailureService
            .new(event[:user], event[:messages])
            .call
        end
      end
    end
  end
end
