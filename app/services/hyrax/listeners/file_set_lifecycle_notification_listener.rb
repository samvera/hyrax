# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for events related to Hydra Works FileSets and sends
    # notifications where needed.
    class FileSetLifecycleNotificationListener
      ##
      # Send a notification to the depositor for failed checksum audits.
      #
      # Called when 'file.set.audited' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_file_set_audited(event)
        return unless event[:result] == :failure # do nothing on success

        Hyrax.logger.error "FIXITY CHECK FAILURE: Fixity failed for #{event[:audit_log]}"

        Hyrax::FixityCheckFailureService
          .new(event[:file_set], checksum_audit_log: event[:audit_log])
          .call
      end

      ##
      # Send a notification to the depositing user for FileSet url import
      # failures.
      #
      # Called when 'file.set.url.imported' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_file_set_url_imported(event)
        Hyrax::ImportUrlFailureService.new(event[:file_set], event[:user]).call if
          event[:result] == :failure
      end
    end
  end
end
