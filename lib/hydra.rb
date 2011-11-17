require "blacklight"
# Hydra libraries
module Hydra
  extend Blacklight::Configurable
  extend ActiveSupport::Autoload
  autoload :Configurable, 'blacklight/configurable'
  autoload :Assets
  autoload :FileAssets
end


require 'mediashelf/active_fedora_helper'

require 'hydra/repository_controller'
require 'hydra/access_controls_enforcement'
require 'hydra/assets_controller_helper'
require 'hydra/file_assets_helper'

require 'hydra/rights_metadata'
require 'hydra/common_mods_index_methods'
require 'hydra/mods_article'
require 'hydra/model_methods'

Dir[File.join(File.dirname(__FILE__), "hydra", "*.rb")].each {|f| require f}
