module Hydra::ModelMixins
  extend ActiveSupport::Autoload
  eager_autoload do
    autoload :ModsObject
    autoload :CommonMetadata
    autoload :RightsMetadata
  end
end
