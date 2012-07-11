require 'hydra-access-controls'

# Hydra libraries
module Hydra
  extend ActiveSupport::Autoload
  autoload :GlobalConfigurable
  extend GlobalConfigurable
  autoload :Assets
  autoload :AssetsControllerHelper
  autoload :Catalog
  autoload :Controller
  autoload :FileAssets
  autoload :Mods
  autoload :ModelMethods
  autoload :RepositoryController
  autoload :RightsMetadata
  autoload :SubmissionWorkflow
  autoload :User
  autoload :UI
  autoload :Workflow

  module ModelMixins
    # We can't autoload ModelMixins, because it's defined by hydra-access-controls
    autoload :CommonMetadata
    autoload :RightsMetadata
    autoload :SolrDocumentExtension
  end
  module Models
    extend ActiveSupport::Autoload
    autoload :FileAsset
  end

end

SolrDocument.use_extension Hydra::ModelMixins::SolrDocumentExtension if defined? SolrDocument

