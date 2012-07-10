require 'hydra-access-controls'

# Hydra libraries
module Hydra
  extend ActiveSupport::Autoload
  autoload :GlobalConfigurable
  extend GlobalConfigurable
  autoload :Assets
  autoload :Catalog
  autoload :Controller
  autoload :FileAssets
  autoload :GenericContent
  autoload :GenericImage
  autoload :GenericUserAttributes
  require 'hydra/model_mixins'
  autoload :RepositoryController
  autoload :SubmissionWorkflow
  autoload :SuperuserAttributes
  autoload :User
  autoload :UI
  autoload :Workflow

end


require 'hydra/assets_controller_helper'
require 'hydra/rights_metadata'
require 'hydra/mods'
require 'hydra/model_methods'
require 'hydra/models/file_asset'
require 'mediashelf/active_fedora_helper' #deprecated

SolrDocument.use_extension Hydra::ModelMixins::SolrDocumentExtension if defined? SolrDocument

