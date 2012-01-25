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

end
