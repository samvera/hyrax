require 'hydra-access-controls'

# Hydra libraries
module Hydra
  extend ActiveSupport::Autoload
  autoload :GlobalConfigurable
  extend GlobalConfigurable
  autoload :Controller
  autoload :ModelMethods
  autoload :RepositoryController
  autoload :Solr

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

begin
  SolrDocument.use_extension Hydra::ModelMixins::SolrDocumentExtension
rescue NameError
end

