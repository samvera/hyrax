module CurationConcerns
  module Models
    def self.config(&block)
      @@config ||= Engine::Configuration.new
      yield @@config if block
      @@config
    end

    class Engine < ::Rails::Engine
      require 'curation_concerns/models/resque'

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
