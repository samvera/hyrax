require "file_asset"
class ImageAsset < FileAsset
  def initialize(attrs = {})
    super(attrs)
    add_relationship(:has_model, "info:fedora/afmodel:FileAsset")
  end

end
