# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for events related to the PCDM Object lifecycles.
    class ObjectLifecycleListener
      ##
      # Called when 'object.deleted' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_deleted(event)
        ContentDeleteEventJob.perform_later(event[:id].to_s, event[:user])
      end

      ##
      # Called when 'object.deposited' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_deposited(event)
        ContentDepositEventJob.perform_later(event[:object], event[:user])
      end

      ##
      # Called when 'object.metadata.updated' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_object_metadata_updated(event)
        ContentUpdateEventJob.perform_later(event[:object], event[:user])
      end
    end
  end
end
