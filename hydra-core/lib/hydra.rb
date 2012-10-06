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
    # ModelMixins already loaded by hydra-access-controls
    autoload :CommonMetadata
    autoload :SolrDocumentExtension
  end
  autoload :Models
end

# require these models once the hydra module has been set up, so that all autoloads take place
#require 'hydra-file-access'

begin
  SolrDocument.use_extension Hydra::ModelMixins::SolrDocumentExtension
rescue NameError
end

