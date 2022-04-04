# frozen_string_literal: true
module Hyrax
  class Engine < ::Rails::Engine
    isolate_namespace Hyrax

    require 'almond-rails'
    require 'awesome_nested_set'
    require 'breadcrumbs_on_rails'
    require 'clipboard/rails'
    require 'draper'
    require 'dry/equalizer'
    require 'dry/events'
    require 'dry/struct'
    require 'dry/validation'
    require 'flipflop'
    require 'flot-rails'
    require 'hydra-file_characterization'
    require 'legato'
    require 'qa'
    require 'tinymce-rails'
    require 'valkyrie'

    require 'hydra/derivatives'
    require 'hyrax/active_fedora_dummy_model'
    require 'hyrax/controller_resource'
    require 'hyrax/form_fields'
    require 'hyrax/indexer'
    require 'hyrax/model_decorator'
    require 'hyrax/publisher'
    require 'hyrax/schema'
    require 'hyrax/search_state'
    require 'hyrax/transactions'
    require 'hyrax/errors'
    require 'hyrax/valkyrie_simple_path_generator'

    # Force these models to be added to Legato's registry in development mode
    config.eager_load_paths += %W[
      #{config.root}/app/models/hyrax/download.rb
      #{config.root}/app/models/hyrax/pageview.rb
    ]

    config.action_dispatch.rescue_responses.merge!(
      "ActiveFedora::ObjectNotFoundError" => :not_found, # We can remove this when we use ActiveFedora 11.2
      "Blacklight::Exceptions::RecordNotFound" => :not_found,
      "Valkyrie::Persistence::ObjectNotFoundError" => :not_found,
      "Hyrax::ObjectNotFoundError" => :not_found
    )

    config.before_initialize do
      # ActionCable should use Hyrax's connection class instead of app's
      config.action_cable.connection_class = -> { 'Hyrax::ApplicationCable::Connection'.safe_constantize }
    end

    config.after_initialize do
      # Attempt to establish a connection before trying to do anything with it. This has to rescue
      # StandardError instead of, e.g., ActiveRecord::ConnectionNotEstablished or ActiveRecord::NoDatabaseError
      # because we can't be absolutely sure what the specific database adapter will raise. pg, for example,
      # raises PG::ConnectionBad. There's no good common ancestor to assume. That's why this test
      # is in its own tiny chunk of code – so we know that whatever the StandardError is, it's coming
      # from the attempt to connect.
      can_connect = begin
        ActiveRecord::Base.connection
        true
                    rescue StandardError
                      false
      end

      can_persist = can_connect && begin
        Hyrax.config.persist_registered_roles!
        Rails.logger.info("Hyrax::Engine.after_initialize - persisting registered roles!")
        true
                                   rescue ActiveRecord::StatementInvalid
                                     false
      end

      unless can_persist
        message = "Hyrax::Engine.after_initialize - unable to persist registered roles.\n"
        message += "It is expected during the application installation - during integration tests, rails install.\n"
        message += "It is UNEXPECTED if you are booting up a Hyrax powered application via `rails server'"
        Rails.logger.info(message)
      end
    end

    initializer 'requires' do
      require 'power_converters'
      require 'wings' unless Hyrax.config.disable_wings
    end

    initializer 'routing' do
      require 'hyrax/rails/routes'
    end

    initializer 'configure' do
      # Allow flipflop to load config/features.rb from the Hyrax gem:
      Flipflop::FeatureLoader.current.append(self)

      Hyrax.config.tap do |c|
        Hydra::Derivatives.ffmpeg_path    = c.ffmpeg_path
        Hydra::Derivatives.temp_file_base = c.temp_file_base
        Hydra::Derivatives.fits_path      = c.fits_path
        Hydra::Derivatives.enable_ffmpeg  = c.enable_ffmpeg
        Hydra::Derivatives.libreoffice_path = c.libreoffice_path

        ActiveFedora::Base.translate_uri_to_id = c.translate_uri_to_id
        ActiveFedora::Base.translate_id_to_uri = c.translate_id_to_uri

        ::Noid::Rails.config.template = c.noid_template
        ::Noid::Rails.config.minter_class = c.noid_minter_class
        ::Noid::Rails.config.statefile = c.minter_statefile
      end
    end

    initializer 'hyrax.assets.precompile' do |app|
      app.config.assets.paths << config.root.join('vendor', 'assets', 'fonts')
      app.config.assets.paths << config.root.join('app', 'assets', 'images')
      app.config.assets.paths << config.root.join('app', 'assets', 'images', 'blacklight')
      app.config.assets.paths << config.root.join('app', 'assets', 'images', 'hydra')
      app.config.assets.paths << config.root.join('app', 'assets', 'images', 'site_images')

      app.config.assets.precompile << /fontawesome-webfont\.(?:svg|ttf|woff)$/
      app.config.assets.precompile += %w[*.png *.jpg *.ico *.gif *.svg]

      Sprockets::ES6.configuration = { 'modules' => 'amd', 'moduleIds' => true }
      # When we upgrade to Sprockets 4, we can ditch sprockets-es6 and config AMD
      # in this way:
      # https://github.com/rails/sprockets/issues/73#issuecomment-139113466
    end
  end
end
