module Hydra::Controller::UploadBehavior
  
  extend Deprecation 
  self.deprecation_horizon = "hydra-core 6.0"
  # Creates a File Asset, adding the posted blob to the File Asset's datastreams and saves the File Asset
  #
  # @return [FileAsset] the File Asset  
  def create_and_save_file_assets_from_params
    if params.has_key?(:Filedata)
      @file_assets = []
      params[:Filedata].each do |file|
        @file_asset = FileAsset.new
        @file_asset.label = file.original_filename
        add_posted_blob_to_asset(@file_asset, file, file.original_filename)
        @file_asset.save!
        @file_assets << @file_asset
      end
      return @file_assets
    else
      render :text => "400 Bad Request", :status => 400
    end
  end
  
  # Puts the contents of params[:Filedata] (posted blob) into a datastream within the given @asset
  # Sets asset label and title to filename if they're empty
  #
  # @param [FileAsset] asset the File Asset to add the blob to
  # @param [#read] file the IO object that is the blob
  # @param [String] file the IO object that is the blob
  # @return [FileAsset] file the File Asset  
  def add_posted_blob_to_asset(asset, file, file_name = nil)
    # deprecating 2 argument constructor because it depends on a HTTP request.  If we pass the file name we can use for non-web too.
    Deprecation.warn(Hydra::Controller::UploadBehavior, "add_posted_blob_to_asset with a 2 argument constructor is deprecated. Pass a filename (e.g. \"file.original_name\") as the third argument. 2 argument constructor will be removed in hydra-core 6" ) if file_name.nil?
    file_name ||= file.original_filename
    asset.add_file(file, datastream_id, file_name)
  end

  #Override this if you want to specify the datastream_id (dsID) for the created blob
  def datastream_id
    "content"
  end
  
  # Associate the new file asset with its container
  def associate_file_asset_with_container(file_asset=nil, container_id=nil)
    if container_id.nil?
      container_id = params[:asset_id]
    end
    if file_asset.nil?
      file_asset = @file_asset
    end
    file_asset.add_relationship(:is_part_of, container_id)
    file_asset.save
  end
  deprecation_deprecate :associate_file_asset_with_container
  
  
end
