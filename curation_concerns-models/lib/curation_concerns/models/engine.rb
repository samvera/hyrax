module CurationConcerns
  module Models
    def self.config(&block)
      @@config ||= Engine::Configuration.new
      yield @@config if block
      @@config
    end

    class Engine < ::Rails::Engine
      require 'curation_concerns/models/resque'

      # Set some configuration defaults
      config.persistent_hostpath = 'http://localhost/files/'
      config.enable_ffmpeg = false
      config.ffmpeg_path = 'ffmpeg'
      config.fits_message_length = 5
      config.temp_file_base = nil
      config.enable_noids = true
      config.noid_template = '.reeddeeddk'
      config.minter_statefile = '/tmp/minter-state'
      config.redis_namespace = 'curation_concerns'
      config.fits_path = 'fits.sh'
      config.enable_local_ingest = nil
      config.queue = CurationConcerns::Resque::Queue

      # Defaulting analytic start date to whenever the file was uploaded by leaving it blank
      config.analytic_start_date = nil

      config.autoload_paths += %W(
        #{config.root}/app/actors/concerns
        #{config.root}/lib/curation_concerns
        #{config.root}/app/models/datastreams
      )

      initializer 'requires' do
        require 'active_fedora/noid'
        require 'curation_concerns/noid'
        require 'curation_concerns/permissions'
      end

      initializer 'configure' do
        CurationConcerns.config.tap do |c|
          Hydra::Derivatives.ffmpeg_path    = c.ffmpeg_path
          Hydra::Derivatives.temp_file_base = c.temp_file_base
          Hydra::Derivatives.fits_path      = c.fits_path
          Hydra::Derivatives.enable_ffmpeg  = c.enable_ffmpeg

          ActiveFedora::Base.translate_uri_to_id = ActiveFedora::Noid.config.translate_uri_to_id
          ActiveFedora::Base.translate_id_to_uri = ActiveFedora::Noid.config.translate_id_to_uri
          ActiveFedora::Noid.config.template = c.noid_template
          ActiveFedora::Noid.config.statefile = c.minter_statefile
        end
      end
    end
  end
end
