# frozen_string_literal: true
require 'rsolr'

module Valkyrie
  module Indexing
    module Solr
      class IndexingAdapter
        COMMIT_PARAMS = { softCommit: true }.freeze
        ##
        # @!attribute [r] connection
        #   @return [RSolr::Client]
        attr_reader :connection

        ##
        # @param connection [RSolr::Client] The RSolr connection to index to.
        def initialize(connection: default_connection)
          @connection = connection
          @resource_indexer = default_indexer
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
          connection.delete_by_id resource.id.to_s, params: COMMIT_PARAMS
        end

        # Delete the Solr index of all Documents
        def wipe!
          connection.delete_by_query("*:*")
          connection.commit
        end

        private

          def persist(resources)
            documents = resources.map do |resource|
              solr_document(resource)
            end
            add_documents(documents)
          end

          def solr_document(resource)
            resource_indexer.for(resource: resource).to_solr
          end

          def add_documents(documents)
            connection.add documents, params: COMMIT_PARAMS
          end

          ##
          # Index configuration based on the blacklight connection.
          def blacklight_based_config
            begin
              # If Blacklight raises an error, we're hopefully running a
              # generator now (if not, the application has bigger problems
              # than this missing configuration)
              bl_index = Blacklight.default_index.connection.uri
            rescue RuntimeError
              return {}
            end

            { 'host' => bl_index.host,
              'port' => bl_index.port,
              'core' => 'hyrax-valkyrie' }
          end

          def connection_url
            config = begin
                       Rails.application.config_for(:valkyrie_index).compact
                     rescue RuntimeError
                       {}
                     end

            # if any configuration is missing, derive it from Blacklight
            config = blacklight_based_config.merge(config)

            "http://#{config['host']}:#{config['port']}/solr/#{config['core']}"
          end

          def default_connection
            RSolr.connect(url: connection_url)
          end

          def default_indexer
            Hyrax::ValkyrieIndexer
          end
      end
    end
  end
end
