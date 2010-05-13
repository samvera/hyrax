class AudioAsset < FileAsset
  def initialize
    super
    add_relationship(:has_model, "info:fedora/afmodel:FileAsset")
  end
end