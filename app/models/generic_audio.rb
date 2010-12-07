# GenericAudio
#
# Default content datastreams: content
#

# this is just a copy of GenericImage for now - so the same methods apply.

require 'hydra'

class GenericAudio < ActiveFedora::Base
  include Hydra::GenericAudio
  include Hydra::ModelMethods
  
  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata 

  has_metadata :name => "descMetadata", :type => Hydra::ModsAudio
  
  # A place to put extra metadata values
  has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
    m.field 'collection', :string
    m.field 'depositor', :string
    m.field 'title', :string
  end
  
  
  # Somewhere to put content info: a stub as per ticket HYDRA-344
  
  has_metadata :name => "contentInfo", :type => ActiveFedora::MetadataDatastream
  
  # Somewhere to put file information etc. as per https://wiki.duraspace.org/display/hydra/contentMetadata+for+Hydra+and+Hydrangea#contentMetadataforHydraandHydrangea-virtual
  
  has_metadata :name => "resourceInfo", :type => Hydra::ResourceInfoMetadata
    
  def initialize( attrs={} )
    super
  end
  
end