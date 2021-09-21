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
        return unless run_jobs(event)
        ContentDepositEventJob.perform_later(event[:object], event[:user])
      end

      ##
      # @param event [Dry::Event]
      def on_object_metadata_updated(event)
        return unless run_jobs(event)
        ContentUpdateEventJob.perform_later(event[:object], event[:user])
      end

      private

      def run_jobs(event)
        # TODO: Jobs should run for all model types, but currently fails for
        #       anything but works and file sets. Pending resolution of Issue #5085
        event[:object].work? || event[:object].file_set?
      end
    end
  end
end
