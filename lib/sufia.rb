require "sufia/version"
require 'blacklight'
require 'blacklight_advanced_search'
require 'hydra/head'
require 'hydra-batch-edit'
require 'sufia/models'

require 'rails_autolink'
require 'sufia/dashboard_controller_behavior'
require "sufia/contact_form_controller_behavior"

autoload :Zip, 'zipruby'
module Sufia
  extend ActiveSupport::Autoload

  class Engine < ::Rails::Engine
    engine_name 'sufia'
 
    config.autoload_paths += %W(
      #{config.root}/app/controllers/concerns
      #{config.root}/app/models/concerns
      #{config.root}/app/models/datastreams
    )

  end

  autoload :Controller
  autoload :HttpHeaderAuth
  autoload :FilesControllerBehavior
  autoload :BatchEditsControllerBehavior
  autoload :DownloadsControllerBehavior
end

