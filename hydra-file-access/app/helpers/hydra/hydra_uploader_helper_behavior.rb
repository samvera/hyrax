require 'deprecation'
module Hydra::HydraUploaderHelperBehavior
  extend Deprecation
  self.deprecation_horizon = 'hydra-head 5.x'
  
  # Generate the appropriate url for posting uploads to
  # Uses the +container_id+ method to figure out what container uploads should go into
  def upload_url
    upload_url = hydra_asset_file_assets_path(:asset_id=>container_id)
  end
  deprecation_deprecate :upload_url
  
  # The id of the container that uploads should be posted into
  # If params[:container_id] is not set, it uses params[:id] (assumes that you're uploading items into the current object)
  def container_id
    if !params[:asset_id].nil?
      return params[:asset_id]
    else
      return params[:id]
    end
  end
  deprecation_deprecate :container_id
end
