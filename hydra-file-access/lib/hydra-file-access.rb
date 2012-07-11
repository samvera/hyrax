module Hydra
  module FileAccess
    require 'hydra/file_access/engine' if defined?(Rails) && Rails::VERSION::MAJOR == 3
  end
  autoload :Assets
  autoload :AssetsControllerHelper
  module Controller
    extend ActiveSupport::Autoload
    autoload :FileAssetsBehavior
    autoload :AssetsControllerBehavior
  end
end
