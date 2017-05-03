# frozen_string_literal: true

class TinymceAsset < ActiveRecord::Base
  mount_uploader :file, TinymceAssetUploader
end
