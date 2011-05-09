# Hydra libraries
module Hydra
  autoload :Configurable, 'blacklight/configurable'
  extend Blacklight::Configurable
end


require 'mediashelf/active_fedora_helper'

require 'hydra/repository_controller'
require 'hydra/access_controls_enforcement'
require 'hydra/testing_server'
require 'hydra/assets_controller_helper'
require 'hydra/file_assets_helper'

require 'hydra/rights_metadata'
require 'hydra/mods_article'
require 'hydra/model_methods'
