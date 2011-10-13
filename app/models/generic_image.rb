# GenericImage
#
# Default content datastreams: content, original (optional), max, thumbnail, screen
#
# Sample Usages:
#  From file:
#   my_image = File.new("#{Rails.root}/spec/fixtures/image.tiff")
#   gi = GenericImage.new
#   gi.content=my_image
#   gi.save
#
#  From url:
#   my_image = "http://example.com/path/to/some/image.jpeg"
#   gi = HydraImage.new
#   gi.content=my_image
#
#  From binary string:
#    my_image = File.open("#{Rails.root}/spec/fixtures/image.tiff")
#    my_blob = my_image.read
#    gi = HydraImage.new
#    gi.content={ :blob=> my_blob, :extension => ".tiff" }
#
#  To create the derived images:
#    gi.derive_all # creates max, screen and thumbnail from content datastream
#    gi.derive_max
#    gi.derive_screen
#    gi.derive_thumbnail
#
#  To get the content of a default datastream:
#    max = gi.max
#    screen = gi.screen
#    thumbnail = gi.thumbnail
#
#  To determine if a particular datastream exists for an image:
#    gi.has_content?
#    gi.has_original?
#    gi.has_max?
#    gi.has_screen?
#    gi.has_thumbnail?
require 'hydra'

class GenericImage < ActiveFedora::Base

  # adds helpful methods for basic hydra objects
  include Hydra::ModelMethods
  
  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  has_metadata :name => "rightsMetadata", :type => Hydra::RightsMetadata 

  include Hydra::GenericImage
  has_metadata :name => "descMetadata", :type => Hydra::ModsImage
  
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