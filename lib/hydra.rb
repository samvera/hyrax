require "blacklight"
require 'active-fedora'
require 'cancan'
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
  autoload :Solr
  autoload :Workflow

  autoload :FileAssetsHelper

  # This error is raised when a user isn't allowed to access a given controller action.
  # This usually happens within a call to AccessControlsEnforcement#enforce_access_controls but can be
  # raised manually.
  class Hydra::AccessDenied < CanCan::AccessDenied; end

  User.send(:include, Hydra::SuperuserAttributes)  #Deprecated

end


require 'hydra/assets_controller_helper'
require 'hydra/rights_metadata'
require 'hydra/mods'
require 'hydra/model_methods'
require 'hydra/models/file_asset'
require 'mediashelf/active_fedora_helper' #deprecated


begin
  SolrDocument.use_extension Hydra::ModelMixins::SolrDocumentExtension
rescue NameError
end
