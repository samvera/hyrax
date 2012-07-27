require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'socket'
require 'sprockets'
require 'resolv'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)
Bundler.require *Rails.groups(:assets => %w(development, test))

module ScholarSphere
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.fits_path = 'fits.sh'
    config.max_days_between_audits = 7
    config.id_namespace = "scholarsphere"
    config.application_name = "ScholarSphere"
    config.persistent_hostpath = "http://scholarsphere.psu.edu/files/"
    # turning on the new asset pipeline for handling javascript, css, and image files
    config.assets.enabled = true
    config.assets.paths << '#{Rails.root}/app/assets/javascripts'
    config.assets.paths << '#{Rails.root}/app/assets/stylesheets'
    config.assets.paths << '#{Rails.root}/app/assets/images'
    config.assets.paths << '#{Rails.root}/lib/assets/javascripts'
    config.assets.paths << '#{Rails.root}/lib/assets/stylesheets'
    config.assets.paths << '#{Rails.root}/lib/assets/images'
    config.assets.paths << '#{Rails.root}/vendor/assets/javascripts'
    config.assets.paths << '#{Rails.root}/vendor/assets/images'
    config.assets.paths << '#{Rails.root}/vendor/assets/fonts'

    # email to send on contact form - probably need one for the production
    # environment
    config.contact_email = 'DLT-GAMMA-PROJECT@lists.psu.edu'

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

    # Map hostnames onto Google Analytics tracking IDs
    config.ga_host_map = {
      'scholarsphere-test.dlt.psu.edu' => 'UA-33252017-1',
      'scholarsphere.psu.edu' => 'UA-33252017-2',
    }

    config.resource_types = {
      "Article"=>"Article",
      "Multimedia"=>"Multimedia",
      "Conference Proceeding"=> "Conference Proceeding",
      "Data Set"=>"Data Set",
      "Image"=>"Image",
      "Thesis"=>"Thesis",
      "Other"=>"Other"
    }

    config.public_permission_levels = {
      "No Access"=>"none",
      "View/Download" => "read"
    }

    config.permission_levels = {
      "No Access"=>"none",
      "View/Download" => "read",
      "Edit" => "edit"
    }

    config.owner_permission_levels = {
      "Edit" => "edit"
    }

    config.cc_licenses = {
      'No license specified' => 'No license specified',
      'Attribution 3.0 United States' => 'http://creativecommons.org/licenses/by/3.0/us/',
      'Attribution-ShareAlike 3.0 United States' => 'http://creativecommons.org/licenses/by-sa/3.0/us/',
      'Attribution-NonCommercial 3.0 United States' => 'http://creativecommons.org/licenses/by-nc/3.0/us/',
      'Attribution-NoDerivs 3.0 United States' => 'http://creativecommons.org/licenses/by-nd/3.0/us/',
      'Attribution-NonCommercial-NoDerivs 3.0 United States' => 'http://creativecommons.org/licenses/by-nc-nd/3.0/us/',
      'Attribution-NonCommercial-ShareAlike 3.0 United States' => 'http://creativecommons.org/licenses/by-nc-sa/3.0/us/',
      'Public Domain Mark 1.0' => 'http://creativecommons.org/publicdomain/mark/1.0/',
      'CC0 1.0 Universal' => 'http://creativecommons.org/publicdomain/zero/1.0/',
      'All rights reserved' => 'All rights reserved'
    }

    # help text to display for form metadata elements, these will need to be updated to
    # reflect a field name change (should one happen) in the generic file datastream
    config.metadata_help = {
      "generic_file_title" => "The title of the object being uploaded to ScholarSphere.",
      "generic_file_tag" => "Keywords, or tags, that describe the object.",
      "generic_file_subject" => "If you would like to align the description of your object with an existing vocabulary of subject terms, enter those here. ScholarSphere supports Library of Congress Subject Headings (LCSH). Begin typing a subject term and ScholarSphere will present you with a list of matching terms.",
      "generic_file_creator" => "The name of a person or group primarily responsible for the creation of the object being uploaded.",
      "generic_file_related_url" => "A URL about the object or the context in which it was created. Example: a link to the research project from which a data set was derived.",
      "generic_file_contributor" => "A person or group that contributed to the object's existence, including schools, colleges, or institutes at Penn State, and funding agencies responsible for funding the research that produced the object.",
      "generic_file_date_created" => "Date on which the object was created in its present form.",
      "generic_file_description" => "A brief description, an abstract, or notes about relationships between this object and other objects to which it is related, providing extra context about the object.",
      "generic_file_identifier" => "A unique handle identifying the object in an external context, e.g. if it has an ISBN, OCLC number, or similar identifying numbers or names.",
      "generic_file_language" => "A language in which the object is expressed.",
      "generic_file_publisher" => "An entity responsible for dissemination of the object.",
      "generic_file_rights" => "A statement about the rights assigned to the object or a content license such as those provided by Creative Commons.  Note that these are not automatically enforced by ScholarSphere, which considers rights, licensing, and access levels separate."
    }

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
# this prevents LoadErrors, related to Rails autoload behavior
require 'scholarsphere/permissions'
require 'scholarsphere/id_service'
require 'scholarsphere/noidify'
require 'scholarsphere/model_methods'
require 'scholarsphere/role_mapper'
