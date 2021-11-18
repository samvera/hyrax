# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for events related to Hydra Works FileSets
    class FileSetLifecycleListener
      ##
      # Called when 'file.set.attached' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_file_set_attached(event)
        FileSetAttachedEventJob.perform_later(event[:file_set], event[:user])
      end

      ##
      # Called when 'file.set.restored' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_file_set_restored(event)
        ContentRestoredVersionEventJob
          .perform_later(event[:file_set], event[:user], event[:revision])
      end
    end
  end
end
