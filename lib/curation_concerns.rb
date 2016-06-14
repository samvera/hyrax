require 'curation_concerns/version'
require 'curation_concerns/engine'
require 'curation_concerns/configuration'
require 'curation_concerns/collections'
require 'blacklight_advanced_search'
require 'kaminari_route_prefix'

module CurationConcerns
  # This method is called once for each statement in the graph.
  def self.id_to_resource_uri
    lambda do |id, graph|
      result = graph.query([nil, ActiveFedora::RDF::Fcrepo::Model.hasModel, nil]).first
      route_key = result.object.to_s.constantize.model_name.singular_route_key
      routes = Rails.application.routes.url_helpers
      builder = ActionDispatch::Routing::PolymorphicRoutes::HelperMethodBuilder
      builder.polymorphic_method routes, route_key, nil, :url, id: id, host: hostname
    end
  end

  def self.hostname
    config.hostname
  end
end
