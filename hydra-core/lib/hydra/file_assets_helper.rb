# will move to lib/hydra/controller / upload_behavior.rb in release 5.x
require 'deprecation'
module Hydra::FileAssetsHelper
  extend ActiveSupport::Concern
  extend Deprecation

  included do
    Deprecation.warn Hydra::FileAssetsHelper, "Hydra::FileAssetsHelper has been moved to Hydra::Controller::UploadBehavior"
    include Hydra::Controller::UploadBehavior
  end

end
