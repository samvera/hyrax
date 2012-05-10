# GenericContent:  EXAMPLE Model that conforms to the Hydra genericContent and genericMetadata cModels 
class GenericContent < ActiveFedora::Base

  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  #  FIXME:  should this have   "include Hydra::ModelMixins::CommonMetadata" instead?
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 

  # Uses the GenericContent mixin to conform to the Hydra genericContent cModel
  include Hydra::GenericContent
  
  has_metadata :name => "descMetadata", :type => Hydra::Datastream::ModsGenericContent

  # A place to put extra metadata values, e.g. the user id of the object depositor (for permissions)
  has_metadata :name => "properties", :type => Hydra::Datastream::Properties
  
  # adds helpful methods for basic hydra objects.  
  # FIXME:  redundate with  GenericContent include above??
  include Hydra::ModelMethods
  
  def initialize( attrs={} )
    super
  end
end
