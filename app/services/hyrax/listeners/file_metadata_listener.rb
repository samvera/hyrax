# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for events related to {Hyrax::FileMetadata}
    class FileMetadataListener
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
    end
  end
end
