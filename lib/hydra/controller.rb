# Include this module into any of your Controller classes to add Hydra functionality
#
# The primary function of this module is to mix in a number of other Hydra Modules, including 
#   Hydra::AccessControlsEnforcement
#
# @example 
#  class CustomHydraController < ApplicationController  
#    include Hydra::Controller
#  end
#
module Hydra::Controller

  def self.included(klass)
    # Other modules to auto-include
    klass.send(:include, Hydra::AccessControlsEnforcement)
    klass.send(:include, MediaShelf::ActiveFedoraHelper)
    klass.send(:include, Hydra::RepositoryController)
  
  
    # Controller filters
    # Also see the generator (or generated CatalogController) to see more before_filters in action
    klass.before_filter :require_solr
    # klass.before_filter :load_fedora_document, :only=>[:show,:edit]
  
    # View Helpers
    klass.helper :hydra
    klass.helper :hydra_assets
  end
  
  # Use params[:id] to load an object from Fedora.  Inspects the object for known models and mixes in any of those models' behaviors.
  # Sets @document_fedora with the loaded object
  # Sets @file_assets with file objects that are children of the loaded object
  def load_fedora_document
    af_base = ActiveFedora::Base.load_instance(params[:id])
    the_model = ActiveFedora::ContentModel.known_models_for( af_base ).first
    unless the_model.include?(ActiveFedora::Relationships)
      the_model.send :include, ActiveFedora::Relationships
    end
    unless the_model.include?(ActiveFedora::FileManagement)
      the_model.send :include, ActiveFedora::FileManagement
    end
    
    @document_fedora = af_base.adapt_to(the_model)
    @file_assets = @document_fedora.file_objects(:response_format=>:solr)
  end
  
  
  # get the currently configured user identifier.  Can be overridden to return whatever (ie. login, email, etc)
  # defaults to using whatever you have set as the Devise authentication_key
  def user_key
    current_user.send(Devise.authentication_keys.first)
  end
  
end
