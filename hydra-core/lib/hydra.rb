require 'hydra-access-controls'

# Hydra libraries
module Hydra
  extend ActiveSupport::Autoload
  autoload :GlobalConfigurable
  extend GlobalConfigurable
  autoload :Catalog
  autoload :Controller
  autoload :ModelMethods
  autoload :RepositoryController

  module ModelMixins
    # We can't autoload ModelMixins, because it's defined by hydra-access-controls
    autoload :CommonMetadata
    autoload :SolrDocumentExtension
  end
  module Models
    extend ActiveSupport::Autoload
    autoload :FileAsset
  end

end

SolrDocument.use_extension Hydra::ModelMixins::SolrDocumentExtension if defined? SolrDocument

