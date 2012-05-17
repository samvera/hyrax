require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'socket'
# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module ScholarSphere
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.fits_path = 'fits.sh'
    config.max_days_between_audits = 7
    config.id_namespace = "scholarsphere"
    config.application_name = "ScholarSphere"
    config.fits_to_desc_mapping = {
      :format_label => :format,
      :last_modified => :date_modified,
      :original_checksum => :identifier,
      :rights_basis => :rights,
      :copyright_basis => :rights,
      :copyright_note => :rights,
      :file_title => :title,
      :file_author => :creator,
      :file_language => :language
    }

    config.logout_url = 'https://webaccess.psu.edu/cgi-bin/logout'
    config.login_url = 'https://webaccess.psu.edu?cosign-'+ Socket.gethostname + '&https://' + Socket.gethostname + '/scholarsphere-integration'

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += Dir["#{config.root}/app/models/**/"] 
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    
    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
  end
end
require 'dil/rights_metadata'
require 'scholarsphere/permissions'
require 'psu/id_service'
require 'psu/noidify'
