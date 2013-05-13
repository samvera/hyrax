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

    # Set some configuration defaults
    config.queue = Sufia::Resque::Queue
    config.enable_ffmpeg = false
    config.noid_template = '.reeddeeddk'
    config.ffmpeg_path = 'ffmpeg'
    config.fits_message_length = 5
    config.temp_file_base = nil
    config.minter_statefile = '/tmp/minter-state'
    config.id_namespace = "sufia"
    config.fits_path = "fits.sh"
    config.enable_contact_form_delivery = false
 
    config.autoload_paths += %W(
      #{config.root}/app/controllers/concerns
      #{config.root}/app/models/concerns
      #{config.root}/app/models/datastreams
    )

  end

  def self.config(&block)
    @@config ||= Sufia::Engine::Configuration.new

    yield @@config if block

    return @@config
  end

  autoload :Controller
  autoload :HttpHeaderAuth
  autoload :FilesControllerBehavior
  autoload :BatchEditsControllerBehavior
  autoload :DownloadsControllerBehavior
end

