module Sufia
  class Engine < ::Rails::Engine
    engine_name 'sufia'

    # These gems must be required outside of an initializer or it doesn't get loaded.
    require 'breadcrumbs_on_rails'
    require 'jquery-ui-rails'
    require 'zeroclipboard-rails'

    config.autoload_paths += %W(
      #{config.root}/app/controllers/concerns
      #{config.root}/app/models/concerns
      #{Hydra::Engine.root}/app/models/concerns
    )

    # Force these models to be added to Legato's registry in development mode
    config.eager_load_paths += %W(
      #{config.root}/app/models/sufia/download.rb
      #{config.root}/app/models/sufia/pageview.rb
    )

    rake_tasks do
      load File.expand_path('../../../tasks/noid.rake', __FILE__)
      load File.expand_path('../../../tasks/reindex.rake', __FILE__)
      load File.expand_path('../../../tasks/stats_tasks.rake', __FILE__)
      load File.expand_path('../../../tasks/sufia_user.rake', __FILE__)
    end

    initializer 'requires' do
      require 'activerecord-import'
      require 'hydra/derivatives'
    end

    initializer 'configure' do
      Sufia.config.tap do |c|
        Hydra::Derivatives.ffmpeg_path    = c.ffmpeg_path
        Hydra::Derivatives.temp_file_base = c.temp_file_base
        Hydra::Derivatives.fits_path      = c.fits_path
        Hydra::Derivatives.enable_ffmpeg  = c.enable_ffmpeg
        Hydra::Derivatives.libreoffice_path = c.libreoffice_path

        ActiveFedora::Base.translate_uri_to_id = c.translate_uri_to_id
        ActiveFedora::Base.translate_id_to_uri = c.translate_id_to_uri
        ActiveFedora::Noid.config.template = c.noid_template
        ActiveFedora::Noid.config.statefile = c.minter_statefile
      end

      CurationConcerns::CurationConcern.actor_factory = Sufia::ActorFactory
      CurationConcerns.config.display_media_download_link = false
    end

    initializer 'sufia.assets.precompile' do |app|
      app.config.assets.paths << config.root.join('vendor', 'assets', 'fonts')
      app.config.assets.paths << config.root.join('app', 'assets', 'images')
      app.config.assets.paths << config.root.join('app', 'assets', 'images', 'blacklight')
      app.config.assets.paths << config.root.join('app', 'assets', 'images', 'hydra')
      app.config.assets.paths << config.root.join('app', 'assets', 'images', 'site_images')

      app.config.assets.precompile << /fontawesome-webfont\.(?:svg|ttf|woff)$/
      app.config.assets.precompile += %w( ZeroClipboard.swf )
      app.config.assets.precompile += %w(*.png *.jpg *.ico *.gif *.svg)

      Sprockets::ES6.configuration = { 'modules' => 'amd', 'moduleIds' => true }
      # When we upgrade to Sprockets 4, we can ditch sprockets-es6 and config AMD
      # in this way:
      # https://github.com/rails/sprockets/issues/73#issuecomment-139113466
    end

    # Set some configuration defaults
    config.persistent_hostpath = "http://localhost/files/"
    config.enable_ffmpeg = false
    config.ffmpeg_path = 'ffmpeg'
    config.fits_message_length = 5
    config.temp_file_base = nil
    config.redis_namespace = "sufia"
    config.fits_path = "fits.sh"
    config.libreoffice_path = "soffice"
    config.enable_contact_form_delivery = false
    config.browse_everything = nil
    config.analytics = false
    config.citations = false
    config.max_notifications_for_dashboard = 5
    config.activity_to_show_default_seconds_since_now = 24 * 60 * 60
    config.arkivo_api = false
    config.geonames_username = ""
    config.active_deposit_agreement_acceptance = true
    config.batch_user_key = 'batchuser@example.com'
    config.audit_user_key = 'audituser@example.com'

    # Should a button with "Share my work" show on the front page to all users (even those not logged in)?
    config.always_display_share_button = true

    # Noid identifiers
    config.enable_noids = true
    config.noid_template = '.reeddeeddk'
    config.minter_statefile = '/tmp/minter-state'
    config.translate_uri_to_id = ActiveFedora::Noid.config.translate_uri_to_id
    config.translate_id_to_uri = ActiveFedora::Noid.config.translate_id_to_uri

    # Defaulting analytic start date to whenever the file was uploaded by leaving it blank
    config.analytic_start_date = nil
  end
end
