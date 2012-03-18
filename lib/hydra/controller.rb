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
    klass.send(:include, Hydra::RepositoryController)
  
    # View Helpers
    klass.helper :hydra
    klass.helper :hydra_assets
  end
  
  # Use params[:id] to load an object from Fedora.  Inspects the object for known models and mixes in any of those models' behaviors.
  # Sets @document_fedora with the loaded object
  # Sets @file_assets with file objects that are children of the loaded object
  def load_fedora_document
    @document_fedora = ActiveFedora::Base.find(params[:id])
    unless @document_fedora.class.include?(Hydra::ModelMethods)
      @document_fedora.class.send :include, Hydra::ModelMethods
    end
    
    @file_assets = @document_fedora.parts(:response_format=>:solr)
  end
  
  
  # get the currently configured user identifier.  Can be overridden to return whatever (ie. login, email, etc)
  # defaults to using whatever you have set as the Devise authentication_key
  def user_key
    current_user.send(Devise.authentication_keys.first)
  end
  
end
