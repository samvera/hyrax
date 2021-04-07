# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for events related to the PCDM Object lifecycles.
    class ObjectLifecycleListener
      ##
      # @param event [Dry::Event]
      def on_object_deleted(event)
        ContentDeleteEventJob.perform_later(event[:id].to_s, event[:user])
      end

      ##
      # @param event [Dry::Event]
      def on_object_deposited(event)
        ContentDepositEventJob.perform_later(event[:object], event[:user])
      end

      ##
      # @param event [Dry::Event]
      def on_object_metadata_updated(event)
        ContentUpdateEventJob.perform_later(event[:object], event[:user])
      end
    end
  end
end
