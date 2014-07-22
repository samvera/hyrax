require 'sufia/models/resque'
module Sufia
  module Models
    def self.config(&block)
      @@config ||= Engine::Configuration.new

      yield @@config if block

      return @@config
    end

    class Engine < ::Rails::Engine

      # Set some configuration defaults
      config.enable_ffmpeg = false
      config.noid_template = '.reeddeeddk'
      config.ffmpeg_path = 'ffmpeg'
      config.fits_message_length = 5
      config.temp_file_base = nil
      config.minter_statefile = '/tmp/minter-state'
      config.id_namespace = "sufia"
      config.fits_path = "fits.sh"
      config.enable_contact_form_delivery = false
      config.browse_everything = nil
      config.enable_local_ingest = nil
      config.analytics = false
      config.queue = Sufia::Resque::Queue
      config.max_notifications_for_dashboard = 5

      config.autoload_paths += %W(
        #{config.root}/app/models/datastreams
      )

      rake_tasks do
        load File.expand_path('../../../tasks/sufia-models_tasks.rake', __FILE__)
      end

      initializer "patches" do
        require 'sufia/models/active_fedora/redis'
        require 'sufia/models/active_record/redis'
      end

      initializer 'requires' do
        require 'activerecord-import'
        require 'hydra/derivatives'
        require 'sufia/models/model_methods'
        require 'sufia/models/file_content'
        require 'sufia/models/file_content/versions'
        require 'sufia/models/user_local_directory_behavior'
        require 'sufia/noid'
        require 'sufia/id_service'
        require 'sufia/analytics'
        require 'sufia/pageview'
        require 'sufia/download'
      end

      initializer 'configure' do
        Hydra::Derivatives.ffmpeg_path    = Sufia.config.ffmpeg_path
        Hydra::Derivatives.temp_file_base = Sufia.config.temp_file_base
        Hydra::Derivatives.fits_path      = Sufia.config.fits_path
        Hydra::Derivatives.enable_ffmpeg  = Sufia.config.enable_ffmpeg
      end
    end
  end
end
