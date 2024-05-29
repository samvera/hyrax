# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for events related to Files ({Valkyrie::StorageAdapter::File})
    class FileListener
      ##
      # Called when 'file.characterized' event is published;
      # allows post-characterization handling, like derivatives generation.
      #
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_file_characterized(event)
        file_set = event[:file_set]

        case file_set
        when ActiveFedora::Base # ActiveFedora
          CreateDerivativesJob
            .perform_later(file_set, event[:file_id], event[:path_hint])
        else
          ValkyrieCreateDerivativesJob
            .perform_later(file_set.id.to_s, event[:file_id])
        end
      end

      ##
      # Called when 'file.uploaded' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_file_uploaded(event)
        # Run characterization for original file only and allow optional skip paramater
        return if event.payload[:skip_derivatives] || !event[:metadata]&.original_file?

        ValkyrieCharacterizationJob.perform_later(event[:metadata].id.to_s)
      end
    end
  end
end
