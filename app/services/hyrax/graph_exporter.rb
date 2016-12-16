module Hyrax
  # Retrieves the graph for an object with the internal triples removed
  # and the uris translated to external uris.
  class GraphExporter
    # @param [SolrDocument] solr_document idea here is that in the future, ActiveFedora may serialize the object as JSON+LD
    # @param [ActionDispatch::Request] request the http request context
    def initialize(solr_document, request)
      @solr_document = solr_document
      @request = request
      @additional_resources = []
    end

    attr_reader :solr_document, :request, :additional_resources

    # @return [RDF::Graph]
    def fetch
      clean_graph_repository.find(solr_document.id).tap do |g|
        additional_resources.uniq.each do |stmt|
          g << stmt
        end
      end
    rescue Ldp::NotFound
      # this error is handled with a 404 page.
      raise ActiveFedora::ObjectNotFoundError
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
        lambda do |resource_id, graph|
          url = ActiveFedora::Base.id_to_uri(resource_id)
          result = graph.query([RDF::URI(url), ActiveFedora::RDF::Fcrepo::Model.hasModel, nil]).first
          if result
            subject_replacer(result, resource_id)
          elsif resource_id.start_with? solr_document.id
            subresource_replacer(resource_id, graph)
          else
            object_replacer(resource_id, graph)
          end
        end
      end

      def subresource_replacer(resource_id, graph)
        parent_id, local = resource_id.split('/', 2)
        parent_url = ActiveFedora::Base.id_to_uri(parent_id)
        result = graph.query([RDF::URI(parent_url), ActiveFedora::RDF::Fcrepo::Model.hasModel, nil]).first

        # OPTIMIZE: we only need to fetch each subresource once.
        additional_resources << ListSourceExporter.new(resource_id, request, subject_replacer(result, parent_id)).fetch
        parent = subject_replacer(result, parent_id)
        "#{parent}/#{local}"
      end

      def subject_replacer(result, resource_id, anchor = nil)
        klass = result.object.to_s.constantize
        route_key = if Hyrax.config.curation_concerns.include?(klass)
                      klass.model_name.singular_route_key
                    else
                      SolrDocument.model_name.singular_route_key
                    end
        routes = Rails.application.routes.url_helpers
        builder = ActionDispatch::Routing::PolymorphicRoutes::HelperMethodBuilder
        builder.polymorphic_method routes, route_key, nil, :url, id: resource_id, host: hostname, anchor: anchor
      end

      def object_replacer(id, _graph)
        id, anchor = id.split('/', 2)
        Rails.application.routes.url_helpers.solr_document_url(id, host: hostname, anchor: anchor)
      end

      def hostname
        request.host
      end
  end
end
