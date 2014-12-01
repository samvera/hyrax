# Include this module into any of your Controller classes to add Hydra functionality
#
# The primary function of this module is to mix in a number of other Hydra Modules, including 
#   Hydra::AccessControlsEnforcement
#
# @example 
#  class CustomHydraController < ApplicationController  
#    include Hydra::Controller::ControllerBehavior
#  end
#
module Hydra::Controller::ControllerBehavior
  extend ActiveSupport::Concern

  included do
    # Other modules to auto-include
    include Hydra::AccessControlsEnforcement
  
    # Catch permission errors
    rescue_from CanCan::AccessDenied do |exception|
      if (exception.action == :edit)
        redirect_to({:action=>'show'}, :alert => exception.message)
      elsif current_user and current_user.persisted?
        redirect_to root_path, :alert => exception.message
      else
        session["user_return_to"] = request.url
        redirect_to new_user_session_path, :alert => exception.message
      end
    end
  end
  
  
  # get the currently configured user identifier.  Can be overridden to return whatever (ie. login, email, etc)
  # defaults to using whatever you have set as the Devise authentication_key
  def user_key
    current_user.user_key if current_user
  end

  module ClassMethods
    # get the solr name for a field with this name and using the given solrizer descriptor
    def solr_name(name, *opts)
      ActiveFedora::SolrQueryBuilder.solr_name(name, *opts)
    end
  end
end
