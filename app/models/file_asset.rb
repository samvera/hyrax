# model for a FileAsset   ActiveFedora object 
#   a file asset is a generic notion of a file, which could have, for example, image or text or video behaviors.
class FileAsset < ActiveFedora::Base
  include Hydra::Models::FileAsset
end
