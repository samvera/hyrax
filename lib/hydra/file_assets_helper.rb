module Hydra::FileAssetsHelper
  
  # Creates a File Asset, adding the posted blob to the File Asset's datastreams and saves the File Asset
  #
  # @return [FileAsset] the File Asset  
  def create_and_save_file_asset_from_params
    if params.has_key?(:Filedata)
      @file_asset = create_asset_from_params
      add_posted_blob_to_asset
      @file_asset.save
      return @file_asset
    else
      render :text => "400 Bad Request", :status => 400
    end
  end
  
  # Puts the contents of params[:Filedata] (posted blob) into a datastream within the given @asset
  #
  # @param [FileAsset] the File Asset to add the blob to
  # @return [FileAsset] the File Asset  
  def add_posted_blob_to_asset(asset=@file_asset)
    asset.add_file_datastream(params[:Filedata], :label=>params[:Filename], :mimeType=>mime_type(params[:Filename]))
  end
  
  # Creates a File Asset and sets its label from params[:Filename]
  #
  # @return [FileAsset] the File Asset
  def create_asset_from_params    
    file_asset = FileAsset.new
    file_asset.label = params[:Filename]
    
    return file_asset
  end
  
  # This is pre-Hydra code that created an AudioAsset, VideoAsset or ImageAsset based on the
  # current params in the controller.
  #
  # @return [Constant] the recommended Asset class
  def asset_class_from_params
    if params.has_key?(:type)
      chosen_type = case params[:type]
      when "AudioAsset"
        AudioAsset
      when "VideoAsset"
        VideoAsset
      when "ImageAsset"
        ImageAsset
      else
        FileAsset
      end
    elsif params.has_key?(:Filename)
      chosen_type = choose_model_by_filename( params[:Filename] )
    else
      chosen_type = FileAsset
    end
    
    return chosen_type
  end
  
  def choose_model_by_filename(filename)
    choose_model_by_filename_extension( File.extname(filename) )
  end
  
  # Rudimentary method to choose an Asset class based on a filename extension
  #
  # @param [String] extension
  # @return [Constant] the recommended Asset class.  Default: FileAsset
  #
  # Recognized extensions: 
  # AudioAsset => ".wav", ".mp3", ".aiff"
  # VideoAsset => ".mov", ".flv", ".mp4"
  # ImageAsset => ".jpeg", ".jpg", ".gif", ".png"
  def choose_model_by_filename_extension(extension)
    case extension
    when ".wav", ".mp3", ".aiff"
      AudioAsset
    when ".mov", ".flv", ".mp4"
      VideoAsset
    when ".jpeg", ".jpg", ".gif", ".png"
      ImageAsset
    else
     FileAsset
    end
  end

  private
  # Return the mimeType for a given file name
  # @param [String] file_name The filename to use to get the mimeType
  # @return [String] mimeType for filename passed in. Default: application/octet-stream if mimeType cannot be determined
  def mime_type file_name
    mime_types = MIME::Types.of(file_name)
    mime_type = mime_types.empty? ? "application/octet-stream" : mime_types.first.content_type
  end
  
end
