# GenericContent:  EXAMPLE Model that conforms to the Hydra genericContent and genericMetadata cModels 
require 'deprecation'
class GenericContent < ActiveFedora::Base
  extend Deprecation

  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  #  FIXME:  should this have   "include Hydra::ModelMixins::CommonMetadata" instead?
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 

  # A place to put extra metadata values, e.g. the user id of the object depositor (for permissions)
  has_metadata :name => "properties", :type => Hydra::Datastream::Properties
  
  # adds helpful methods for basic hydra objects.  
  # FIXME:  redundate with  GenericContent include above??
  include Hydra::ModelMethods
  
  def initialize( attrs={} )
    Deprecation.warn(GenericContent, "GenericContent is deprecated and will be removed in hydra-head 5.x")
    super
  end
end
