# frozen_string_literal: true

module Hyrax
  module Listeners
    ##
    # Listens for events related to nesting indexing
    class NestingIndexingListener
      ##
      # Called when 'collection.metadata.updated' event is published
      # @param [Dry::Events::Event] event
      # @return [void]
      def on_collection_metadata_updated(event)
#        Hyrax.config.nested_relationship_reindexer.call(id: event[:collection].id.to_s, extent: Hyrax::Adapters::NestingIndexAdapter::FULL_REINDEX)
      end
    end
  end
end
