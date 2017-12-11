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
      @visited_subresources = Set.new
    end

    attr_reader :solr_document, :request, :additional_resources

    # @return [RDF::Graph]
    def fetch
      resource = Hyrax::Queries.find_by(id: Valkyrie::ID.new(@solr_document.id))
      schema = Valkyrie::MetadataAdapter.find(:fedora).schema
      graph = RDF::Graph.new
      uri = RDF::URI(subject_replacer(resource.class, resource.id.to_s))
      resource.attributes.each do |key, value|
        next if value.blank?
        # TODO: add special case for member_ids
        predicate = schema.predicate_for(resource: resource, property: key)
        Array.wrap(value).each do |v|
          graph << [uri, predicate, v]
        end
      end
      graph
    end

    private

      def subject_replacer(klass, resource_id, anchor = nil)
        route_key = if Hyrax.config.curation_concerns.include?(klass)
                      klass.model_name.singular_route_key
                    else
                      SolrDocument.model_name.singular_route_key
                    end
        routes = Rails.application.routes.url_helpers
        builder = ActionDispatch::Routing::PolymorphicRoutes::HelperMethodBuilder
        builder.polymorphic_method routes, route_key, nil, :url, id: resource_id, host: hostname, anchor: anchor
      end

      def hostname
        request.host
      end
  end
end
