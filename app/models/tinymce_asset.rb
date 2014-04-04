class TinymceAsset < ActiveRecord::Base
  mount_uploader :file, TinymceAssetUploader
end
