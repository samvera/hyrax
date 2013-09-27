require 'hydra-access-controls'

module Hydra
  extend ActiveSupport::Autoload
  autoload :GlobalConfigurable
  extend GlobalConfigurable
  autoload :Controller
  autoload :ModelMethods
  autoload :RepositoryController
  autoload :Solr
  module ModelMixins
    # ModelMixins already loaded by hydra-access-controls
    autoload :CommonMetadata
    autoload :SolrDocumentExtension
  end
  autoload :Models
end

module HydraHead 
  require 'hydra-head/engine' if defined?(Rails)
  require 'hydra-head/routes'
  # If you put this in your application's routes.rb, it will add the Hydra Head routes to the app.
  # The hydra:head generator puts this in routes.rb for you by default.
  # See {HydraHead::Routes} for information about how to modify which routes are generated.
  # @example 
  #   # in config/routes.rb
  #   MyAppName::Application.routes.draw do
  #     Blacklight.add_routes(self)
  #     HydraHead.add_routes(self)
  #   end
  def self.add_routes(router, options = {})
    HydraHead::Routes.new(router, options).draw
  end
end

ActiveSupport.on_load(:after_initialize) do
  begin
    SolrDocument.use_extension Hydra::ModelMixins::SolrDocumentExtension
  rescue NameError
    logger.warn "Couldn't find SolrDocument"
  end
end
