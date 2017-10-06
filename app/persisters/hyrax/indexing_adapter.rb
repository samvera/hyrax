# frozen_string_literal: true
# This was copied out of the Valkyrie app and I don't know why it isn't part of
# the valkyrie gem. -- Justin
##
module Hyrax
  # The {IndexingAdapter} enables a choice between indexing into another
  # persister concurrently (via `#save`), or by doing a series of actions with the
  # primary persister, tracking those actions, and then persisting them all into
  # the `index_adapter` via a large `save_all` call. This is particularly
  # efficient when the `index_adapter` is significantly faster for `save_all`
  # than individual `saves` (such as with Solr).
  class IndexingAdapter
    attr_reader :metadata_adapter, :index_adapter
    # @param metadata_adapter [#persister,#query_service]
    # @param index_adapter [#persister,#query_service]
    def initialize(metadata_adapter:, index_adapter:)
      @metadata_adapter = metadata_adapter
      @index_adapter = index_adapter
    end

    def persister
      IndexingAdapter::Persister.new(metadata_adapter: self)
    end

    delegate :query_service, to: :metadata_adapter

    class Persister
      attr_reader :metadata_adapter
      delegate :index_adapter, to: :metadata_adapter
      delegate :persister, to: :primary_adapter
      def initialize(metadata_adapter:)
        @metadata_adapter = metadata_adapter
      end

      def primary_adapter
        metadata_adapter.metadata_adapter
      end

      def index_persister
        index_adapter.persister
      end

      # (see Valkyrie::Persistence::Memory::Persister#save)
      # @note This saves into both the `persister` and `index_persister`
      #   concurrently.
      def save(resource:)
        composite_persister.save(resource: resource)
      end

      # (see Valkyrie::Persistence::Memory::Persister#save_all)
      # @note This saves into both the `persister` and `index_persister`
      #   concurrently.
      def save_all(resources:)
        composite_persister.save_all(resources: resources)
      end

      # (see Valkyrie::Persistence::Memory::Persister#delete)
      # @note This deletes from both the `persister` and `index_persister`
      #   concurrently.
      def delete(resource:)
        composite_persister.delete(resource: resource)
      end

      def wipe!
        composite_persister.wipe!
      end

      # Yields the primary persister. At the end of the block, this will use changes tracked
      # by an in-memory persister to replicate new and deleted objects into the
      # `index_persister` in bulk.
      #
      # @example Creating two items
      #   indexing_persister.buffer_into_index do |persister|
      #     persister.save(resource: Book.new)
      #     persister.save(resource: Book.new)
      #     solr_index.query_service.find_all # => []
      #     persister.query_service.find_all # => [book1, book2]
      #   end
      #   solr_index.query_service.find_all # => [book1, book2]
      def buffer_into_index
        buffered_persister.with_buffer do |persist, buffer|
          yield Valkyrie::AdapterContainer.new(persister: persist, query_service: metadata_adapter.query_service)
          buffer.persister.deletes.uniq(&:id).each do |delete|
            index_persister.delete(resource: delete)
          end
          index_persister.save_all(resources: buffer.query_service.find_all)
        end
      end

      def composite_persister
        @composite_persister ||= Valkyrie::Persistence::CompositePersister.new(persister, index_persister)
      end

      def buffered_persister
        @buffered_persister ||= Valkyrie::Persistence::BufferedPersister.new(persister)
      end
    end
  end
end
