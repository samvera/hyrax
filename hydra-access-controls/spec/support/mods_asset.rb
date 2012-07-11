require 'active-fedora'
class ModsAsset < ActiveFedora::Base
  include Hydra::ModelMixins::RightsMetadata
  has_metadata :name => "rightsMetadata", :type => Hydra::Datastream::RightsMetadata
  
  # This is how we're associating admin policies with assets.  
  # You can associate them however you want, just use the :is_governed_by relationship
  belongs_to :admin_policy, :class_name=> "Hydra::AdminPolicy", :property=>:is_governed_by
end
