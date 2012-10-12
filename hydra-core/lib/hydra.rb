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
