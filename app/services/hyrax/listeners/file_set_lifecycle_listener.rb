# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for events related to Hydra Works FileSets
    class FileSetLifecycleListener
      ##
      # @param event [Dry::Event]
      def on_file_set_attached(event)
        FileSetAttachedEventJob.perform_later(event[:file_set], event[:user])
      end

      ##
      # @param event [Dry::Event]
      def on_file_set_audited(event)
        return unless event[:result] == :failure # do nothing on success

        Hyrax::FixityCheckFailureService
          .new(event[:file_set], checksum_audit_log: event[:audit_log])
          .call
      end

      ##
      # @param event [Dry::Event]
      def on_file_set_url_imported(event)
        Hyrax::ImportUrlFailureService.new(event[:file_set], event[:user]).call if
          event[:result] == :failure
      end

      ##
      # @param event [Dry::Event]
      def on_file_set_restored(event)
        ContentRestoredVersionEventJob
          .perform_later(event[:file_set], event[:user], event[:revision])
      end
    end
  end
end
