module Hyrax
  # Retrieves the graph for an object with the internal triples removed
  # and the uris translated to external uris.
  class ListSourceExporter
    # @param [String] id
    # @param [ActionDispatch::Request] request the http request context
    # @param [String] parent_url
    def initialize(id, request, parent_url)
      @id = id
      @request = request
      @parent_url = parent_url
    end

    attr_reader :id, :request, :parent_url

    # @return [RDF::Graph]
    def fetch
      clean_graph_repository.find(id)
    end

    private

      def clean_graph_repository
        Hydra::ContentNegotiation::CleanGraphRepository.new(connection, replacer)
      end

      def connection
        @connection ||= CleanConnection.new(ActiveFedora.fedora.connection)
      end

      # This method is called once for each statement in the graph.
      def replacer
        lambda do |resource_id, _graph|
          parent_id = ActiveFedora::Base.uri_to_id(parent_url)
          return parent_url + resource_id.sub(parent_id, '') if resource_id.start_with?(parent_id)
          Rails.application.routes.url_helpers.solr_document_url(resource_id, host: hostname)
        end
      end

      def hostname
        request.host
      end
  end
end
