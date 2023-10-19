# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for events related to {Hyrax::FileMetadata}
    class FileMetadataListener
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
      # Called when 'file.metadata.updated' event is published; reindexes a
      # {Hyrax::FileSet} when a file claiming to be its `pcdm_use:OriginalFile`
      #
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_file_metadata_updated(event)
        return unless event[:metadata].original_file?

        file_set = Hyrax.query_service.find_by(id: event[:metadata].file_set_id)
        Hyrax.index_adapter.save(resource: file_set)
      rescue Valkyrie::Persistence::ObjectNotFoundError => err
        Hyrax.logger.warn "tried to index file with id #{event[:metadata].id} " \
                          "in response to an event of type #{event.id} but " \
                          "encountered an error #{err.message}. should this " \
                          "object be in a FileSet #{event[:metadata]}"
      end

      ##
      # Called when 'file.uploaded' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_file_uploaded(event)
        # Run characterization for original file only
        return unless event[:metadata]&.original_file?

        ValkyrieCharacterizationJob.perform_later(event[:metadata].id.to_s)
      end
    end
  end
end
