require "hydra/access_controls_enforcement"
# Include this module into any of your Blacklight Catalog classes (ie. CatalogController) to add Hydra functionality
#
# The primary function of this module is to mix in a number of other Hydra Modules, including 
#   Hydra::AccessControlsEnforcement
#
# This module will only work if you also include Blacklight::Catalog in the Controller you're extending.
# The hydra head rails generator will create the CatalogController for you in app/controllers/catalog_controller.rb
# @example 
#  require 'blacklight/catalog'
#  require 'hydra/catalog'
#  class CustomCatalogController < ApplicationController  
#    include Blacklight::Catalog
#    include Hydra::Catalog
#  end
module Hydra::Catalog
  
  def self.included(klass)
    klass.send(:include, Hydra::AccessControlsEnforcement)
  end
  
  def edit
  end
  
end