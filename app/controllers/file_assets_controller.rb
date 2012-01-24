class FileAssetsController < ApplicationController
  include Hydra::FileAssets

  protected

  def create_asset_from_file(file)
    file_asset = GenericFile.new
    file_asset.label = file.original_filename
    file_asset
  end

end
