module Hyrax
  class Engine < ::Rails::Engine
    isolate_namespace Hyrax

    # These gems must be required outside of an initializer or they don't get loaded.
    require 'awesome_nested_set'
    require 'breadcrumbs_on_rails'
    require 'jquery-ui-rails'
    require 'flot-rails'
    require 'almond-rails'
    require 'jquery-datatables-rails'
    require 'flipflop'
    require 'qa'
    require 'clipboard/rails'
    require 'legato'

    # Force these models to be added to Legato's registry in development mode
    config.eager_load_paths += %W(
      #{config.root}/app/models/hyrax/download.rb
      #{config.root}/app/models/hyrax/pageview.rb
    )

    initializer 'requires' do
      require 'hydra/derivatives'
      require 'hyrax/name'
      require 'hyrax/controller_resource'
      require 'hyrax/search_state'
      require 'hyrax/single_use_error'
      require 'hyrax/workflow_authorization_exception'
      require 'power_converters'
      require 'dry/struct'
      require 'dry/equalizer'
      require 'dry/validation'
    end

    initializer 'routing' do
      require 'hyrax/rails/routes'
    end

    initializer 'configure' do
      # Set the path for the flipflop config:
      Flipflop::Engine.config_file = Hyrax::Engine.root + "config/features.rb"

      Hyrax.config.tap do |c|
        Hydra::Derivatives.ffmpeg_path    = c.ffmpeg_path
        Hydra::Derivatives.temp_file_base = c.temp_file_base
        Hydra::Derivatives.fits_path      = c.fits_path
        Hydra::Derivatives.enable_ffmpeg  = c.enable_ffmpeg
        Hydra::Derivatives.libreoffice_path = c.libreoffice_path

        ActiveFedora::Base.translate_uri_to_id = c.translate_uri_to_id
        ActiveFedora::Base.translate_id_to_uri = c.translate_id_to_uri

        ActiveFedora::Noid.config.template = c.noid_template
        ActiveFedora::Noid.config.minter_class = c.noid_minter_class
        ActiveFedora::Noid.config.statefile = c.minter_statefile
      end

      Hyrax::CurationConcern.actor_factory = Hyrax::ActorFactory
    end

    initializer 'hyrax.assets.precompile' do |app|
      app.config.assets.paths << config.root.join('vendor', 'assets', 'fonts')
      app.config.assets.paths << config.root.join('app', 'assets', 'images')
      app.config.assets.paths << config.root.join('app', 'assets', 'images', 'blacklight')
      app.config.assets.paths << config.root.join('app', 'assets', 'images', 'hydra')
      app.config.assets.paths << config.root.join('app', 'assets', 'images', 'site_images')

      app.config.assets.precompile << /fontawesome-webfont\.(?:svg|ttf|woff)$/
      app.config.assets.precompile += %w(*.png *.jpg *.ico *.gif *.svg)
      app.config.assets.precompile += %w(hyrax/admin.css)

      Sprockets::ES6.configuration = { 'modules' => 'amd', 'moduleIds' => true }
      # When we upgrade to Sprockets 4, we can ditch sprockets-es6 and config AMD
      # in this way:
      # https://github.com/rails/sprockets/issues/73#issuecomment-139113466
    end
  end
end
