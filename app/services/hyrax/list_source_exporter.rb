# frozen_string_literal: true
module Hyrax
  # Retrieves the graph for an object with the internal triples removed
  # and the uris translated to external uris.
  class ListSourceExporter
    ##
    # @param [String] id
    # @param [ActionDispatch::Request] request the http request context
    # @param [String] parent_url
    # @param [String] hostname  the current http host
    def initialize(id, request, parent_url, hostname: nil)
      @id = id
      @request = request
      @hostname = hostname || request.host
      @parent_url = parent_url
    end

    ##
    # @!attribute [r] id
    #   @return [String]
    # @!attribute [r] parent_url
    #   @return [String]
    # @!attribute [r] request
    #   @deprecated use {#hostname} to access the host
    #   @return [ActionDispatch::Request]
    # @!attribute [r] hostname
    #   @return [String]
    attr_reader :id, :request, :parent_url, :hostname
    deprecation_deprecate :request

    ##
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
        parent_id = Hyrax::Base.uri_to_id(parent_url)
        return parent_url + resource_id.sub(parent_id, '') if resource_id.start_with?(parent_id)
        Rails.application.routes.url_helpers.solr_document_url(resource_id, host: hostname)
      end
    end
  end
end
