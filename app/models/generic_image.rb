# GenericImage: 
#   EXAMPLE Model that conforms to the Hydra genericImage, genericMetadata and genericContent cModels
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

  # Uses the GenericImage mixin to conform to the Hydra genericImage cModel (auto-includes on GenericContent behaviors)
  include Hydra::GenericImage

  # adds helpful methods for basic hydra objects
  include Hydra::ModelMethods
  
  # Uses the Hydra Rights Metadata Schema for tracking access permissions & copyright
  #  FIXME:  should this have   "include Hydra::ModelMixins::CommonMetadata" instead?
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata 

  has_metadata :name => "descMetadata", :type => Hydra::Datastream::ModsImage
  
  # A place to put extra metadata values, e.g. the user id of the object depositor (for permissions)
  has_metadata :name => "properties", :type => Hydra::Datastream::Properties
  
  def initialize( attrs={} )
    super
  end
  
end
