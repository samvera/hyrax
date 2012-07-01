# Hydra-repository Contoller is a controller layer mixin. It is in the controller scope: request params, session etc.
# 
# will move to lib/hydra/controller/repository_controller_behavior in release 5.x
# 
# NOTE: Be careful when creating variables here as they may be overriding something that already exists.
# The ActionController docs: http://api.rubyonrails.org/classes/ActionController/Base.html
#
# Override these methods in your own controller for customizations:
# 
# class HomeController < ActionController::Base
#   
#   include Stanford::SolrHelper
#   
#   def solr_search_params
#     super.merge :per_page=>10
#   end
#   
# end
#
module Hydra::RepositoryController
  extend ActiveSupport::Concern

  included do
    ActiveSupport::Deprecation.warn "Hydra::RepositoryController has moved to Hydra::Controller::RepositoryControllerBehavior"
    include Hydra::Controller::RepositoryControllerBehavior
  end
  
end
