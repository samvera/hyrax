class FileAssetsController < ApplicationController
  include Hydra::FileAssets

  def new
    @file_asset = GenericFile.new 
  end

  protected

  def create_asset_from_file(file)
    file_asset = GenericFile.new
    file_asset.label = file.original_filename
    file_asset
  end

  # Puts the contents of params[:Filedata] (posted blob) into a datastream within the given @asset
  # Sets asset label and title to filename if they're empty
  #
  # @param [FileAsset] the File Asset to add the blob to
  # @return [FileAsset] the File Asset  
  def add_posted_blob_to_asset(asset,file)
    file_name = file.original_filename
    options = {:label=>file_name, :mimeType=>mime_type(file_name), :checksumType=>'MD5' }
    dsid = datastream_id #Only call this once so that it could be a sequence
    options[:dsid] = dsid if dsid
    asset.add_file_datastream(file, options)
    asset.set_title_and_label( file_name, :only_if_blank=>true )
  end
end
