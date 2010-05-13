module Hydra::AssetsControllerHelper
  
  def retrieve_af_model(class_name)
    klass = Module.const_get(class_name.camelcase)
    #klass.included_modules.include?(ActiveFedora::Model)  
    if klass.is_a?(Class) && klass.superclass == ActiveFedora::Base
      return klass
    else
      return false
    end
    rescue NameError
      return false
  end
  
  def create_and_save_file_asset_from_params
    if params.has_key?(:Filedata)
      @file_asset = create_asset_from_params
      add_posted_blob_to_asset
      @file_asset.save
    else
      render :text => "400 Bad Request", :status => 400
    end
  end
  
  def add_posted_blob_to_asset
    @file_asset.add_file_datastream(params[:Filedata], :label=>params[:Filename])
  end
  
  def create_asset_from_params    
    file_asset = asset_class_from_params.new
    file_asset.label = params[:Filename]
    
    return file_asset
  end
  
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
    
  #underscores are escaped w/ + signs, which are unescaped by rails to spaces
  def unescape_keys(attrs)
    h=Hash.new
    attrs.each do |k,v|
      h[k.gsub(/ /, '_')]=v

    end
    h
  end
  def escape_keys(attrs)
    h=Hash.new
    attrs.each do |k,v|
      h[k.gsub(/_/, '+')]=v

    end
    h
  end
  
end