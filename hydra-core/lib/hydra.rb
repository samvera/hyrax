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
  autoload :GenericContent
  autoload :GenericImage
  autoload :GenericUserAttributes
  autoload :Mods
  autoload :ModelMixins
  autoload :ModelMethods
  autoload :RepositoryController
  autoload :RightsMetadata
  autoload :SubmissionWorkflow
  autoload :SuperuserAttributes
  autoload :User
  autoload :UI
  autoload :Workflow

end


require 'hydra/models/file_asset'

SolrDocument.use_extension Hydra::ModelMixins::SolrDocumentExtension if defined? SolrDocument

