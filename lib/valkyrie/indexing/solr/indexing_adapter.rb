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
        attr_accessor :connection

        ##
        # @param connection [RSolr::Client] The RSolr connection to index to.
        def initialize(connection: default_connection)
          @connection = connection
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

        def reset!
          self.connection = default_connection
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
          rescue StandardError
            return {}
          end

          {
            'host' => bl_index.host,
            'user' => bl_index.user,
            'password' => bl_index.password,
            'scheme' => bl_index.scheme,
            'port' => bl_index.port,
            'core' => bl_index.path.split("/")[2] || 'hyrax-valkyrie'
          }.compact
        end

        def connection_url
          config = begin
                     Rails.application.config_for(:valkyrie_index).compact
                   rescue RuntimeError
                     {}
                   end

          # Given how we're building blacklight_based_config, there won't be a URL.  So let's avoid
          # that whole logic path.
          return config['url'] if config['url'].present?

          # Derive any missing configuration from Blacklight.
          config = blacklight_based_config.with_indifferent_access.merge(config)

          url = "#{config.fetch('scheme', 'http')}://"
          url = "#{url}#{config['user']}:#{config['password']}@" if config.key?('user') && config.key?('password')

          "#{url}#{config['host']}:#{config['port']}/solr/#{config['core']}"
        end

        def default_connection
          RSolr.connect(url: connection_url)
        end

        def resource_indexer
          Hyrax::Indexers::ResourceIndexer
        end
      end
    end
  end
end
