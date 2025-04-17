# frozen_string_literal: true
module Valkyrie
  module Indexing
    module RedisQueue
      class IndexingAdapter
        ##
        # @!attribute [r] connection
        #   @return [RSolr::Client]
        attr_writer :connection
        attr_accessor :index_queue_name, :delete_queue_name

        ##
        # @param connection [RSolr::Client] The RSolr connection to index to.
        def initialize(connection: nil, index_queue_name: 'toindex', delete_queue_name: 'todelete')
          @connection = connection
          @index_queue_name = index_queue_name
          @delete_queue_name = delete_queue_name
        end

        def connection
          @connection ||= default_connection
        end

        def save(resource:)
          persist([resource])
        end

        def save_all(resources:)
          persist(resources)
        end

        # Deletes a Solr Document using the ID
        # @return [Array<Valkyrie::Resource>] resources which have been deleted from Solr
        def delete(resource:)
          connection.zadd(delete_queue_name, Time.current.to_i, resource.id.to_s)
        end

        # Delete the Solr index of all Documents
        def wipe!
          connection.del(index_queue_name)
          connection.del(delete_queue_name)
        end

        def reset!
          self.connection = default_connection
        end

        def index_queue(size: 200)
          set = connection.zpopmin(index_queue_name, size)
          return [] if set.blank?
          # we have to load these one at a time because find_all_by_id gets duplicates during wings transition
          resources = set.map { |id, _time| Hyrax.query_service.find_by(id: id) }
          solr_indexer = Valkyrie::IndexingAdapter.find(:solr_index)
          solr_indexer.save_all(resources: resources)
          solr_indexer.connection.commit
        rescue
          # if anything goes wrong, try to requeue the items
          set.each { |id, time| connection.zadd(index_queue_name, time, id) }
          raise
        end

        # We reach in to solr directly here to prevent needing to load the objects unnecessarily
        def delete_queue(size: 200)
          set = connection.zpopmin(delete_queue_name, size)
          return [] if set.blank?
          solr_indexer = Valkyrie::IndexingAdapter.find(:solr_index)
          set.each do |id, _time|
            solr_indexer.connection.delete_by_id id.to_s, { softCommit: true }
          end
          solr_indexer.connection.commit
        rescue
          # if anything goes wrong, try to requeue the items
          set.each { |id, time| connection.zadd(delete_queue_name, time, id) }
          raise
        end

        def list_index
          connection.zrange(index_queue_name, 0, -1, with_scores: true)
        end

        def list_delete
          connection.zrange(delete_queue_name, 0, -1, with_scores: true)
        end

        private

        def persist(resources)
          resources.map do |r|
            connection.zadd(index_queue_name, Time.current.to_i, r.id.to_s)
          end
        end

        def default_connection
          Hyrax.config.redis_connection
        end
      end
    end
  end
end
