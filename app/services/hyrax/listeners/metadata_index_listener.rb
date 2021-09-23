# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Reindexes resources when their metadata is updated.
    #
    # @note This listener makes no attempt to avoid reindexing when no metadata
    #   has actually changed, or when real metadata changes won't impact the
    #   indexed data. We trust that published metadata update events represent
    #   actual changes to object metadata, and that the indexing adapter
    #   optimizes reasonably for actual index document contents.
    class MetadataIndexListener
      ##
      # Re-index the resource.
      #
      # @param event [Dry::Event]
      def on_collection_metadata_updated(event)
        metadata_updated(event, :collection)
      end

      ##
      # Re-index the resource.
      #
      # @param event [Dry::Event]
      def on_object_metadata_updated(event)
        metadata_updated(event, :object)
      end

      ##
      # Remove the resource from the index.
      #
      # @param event [Dry::Event]
      def on_object_deleted(event)
        log_non_resource(event.payload) && return unless
          event.payload[:object].is_a?(Valkyrie::Resource)

        Hyrax.index_adapter.delete(resource: event[:object])
      end

      private

      def log_non_resource(event)
        Hyrax.logger.info('Skipping object reindex because the object ' \
                          "#{event[:object]} was not a Valkyrie::Resource.")
      end

      def metadata_updated(event, idx)
        log_non_resource(event) && return unless
          event[idx].is_a?(Valkyrie::Resource)

        Hyrax.index_adapter.save(resource: event[idx])
      end
    end
  end
end
