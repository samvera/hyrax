# frozen_string_literal: true
module Valkyrie
  module Indexing
    module RedisQueue
      class IndexingAdapter
        ##
        # @!attribute [r] connection
        #   @return [RSolr::Client]
        attr_accessor :connection, :index_queue_name, :delete_queue_name

        ##
        # @param connection [RSolr::Client] The RSolr connection to index to.
        def initialize(connection: default_connection, index_queue_name: 'toindex', delete_queue_name: 'todelete')
          @connection = connection
          @index_queue_name = index_queue_name
          @delete_queue_name = delete_queue_name
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
          connection.sadd(delete_queue_name, resource.id.to_s)
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
          set = connection.spop(index_queue_name, size)
          return [] if set.blank?
          resources = Hyrax.query_service.find_many_by_ids(ids: set)
          Valkyrie::IndexingAdapter.find(:solr_index).save_all(resources: resources)
        rescue
          persist(set) # if anything goes wrong, try to requeue the items
        end

        # We reach in to solr directly here to prevent needing to load the objects unnecessarily
        def delete_queue(size: 200)
          set = connection.spop(index_queue_name, size)
          return [] if set.blank?
          indexer = Valkyrie::IndexingAdapter.find(:solr_index)
          set.each do |id|
            indexer.connection.delete_by_id id.to_s, { softCommit: true }
          end
          indexer.connection.commit
        rescue
          persist(set) # if anything goes wrong, try to requeue the items
        end

        private

        def persist(resources)
          connection.sadd(index_queue_name, resources.map {|r| r.id.to_s})
        end

        def default_connection
          Hyrax.config.redis_connection
        end
      end
    end
  end
end
