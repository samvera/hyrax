require 'sanitize'
require 'deprecation'
module Hydra::HydraAssetsHelperBehavior
  extend Deprecation
  self.deprecation_horizon = 'hydra-head 5.x'

  def get_file_asset_count(document)
    count = 0
    ### TODO switch to AF::Base.count
    obj = ActiveFedora::Base.load_instance_from_solr(document['id'], document)
    count += obj.parts.length unless obj.nil?
    count
  end
 # deprecation_deprecate :get_file_asset_count
  
end
