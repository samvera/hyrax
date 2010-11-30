# GenericAudio
#
# Default content datastreams: content, original (optional), max, thumbnail, screen
#

# this is just a copy of GenericImage for now - so the same methods apply.

require 'hydra'

class GenericAudio < ActiveFedora::Base
  include Hydra::GenericAudio
  include Hydra::ModelMethods
  
  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata 

  has_metadata :name => "descMetadata", :type => ActiveFedora::QualifiedDublinCoreDatastream
  
  # A place to put extra metadata values
  has_metadata :name => "properties", :type => ActiveFedora::MetadataDatastream do |m|
    m.field 'collection', :string
    m.field 'depositor', :string
    m.field 'title', :string
  end
  
  def initialize( attrs={} )
    super
  end
  
end