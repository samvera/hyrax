require 'hydra'

class GenericContent < ActiveFedora::Base
  include Hydra::ModelMethods
  include Hydra::GenericContent
  
  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata 

  has_metadata :name => "descMetadata", :type => Hydra::ModsGenericContent

  # A place to put extra metadata values
  has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
    m.field 'collection', :string
    m.field 'depositor', :string
  end
  
  def initialize( attrs={} )
    super
  end
end
