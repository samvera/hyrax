require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'socket'
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
    # turning on the new asset pipeline for handling javascript, css, and image files
    config.assets.enabled = true
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
      "Discover" => "discover",
      "View" => "read" 
    } 
    config.permission_levels = {
      "No Access"=>"none",
      "Discover" => "discover",
      "View" => "read",
      "Edit" => "edit"
    }

    # help text to display for form metadata elements, these will need to be updated to 
    # reflect a field name change (should one happen) in the generic file datastream
    config.metadata_help = {
      "generic_file_title" => "The name of the object being uploaded to ScholarSphere.",
      "generic_file_tag" => "Terms which describe the object. They do not need to belong to any controlled vocabulary.",
      "generic_file_subject" => "If you would like to align the description of your object with an existing vocabulary of subject terms, enter those here. Currently we support Library of Congress Subject Headings (LCSH); we hope to add additional subject-specific vocabularies (MESH, etc.) in the future. Enter part of a term and ScholarSphere will try to predict the subject heading you are adding.",
      "generic_file_creator" => "The name of the person or group primarily responsible for the creation of the object being uploaded.",
      "generic_file_related_url" => "A URL about the object or the context in which it was created. Example: a link to the research project from which a data set was derived.", 
      "generic_file_contributor" => "Any additional persons or groups responsible for the object's existence, e.g. schools, colleges, or institutes at Penn State; funding agencies responsible for funding the research which produced the object, etc.",
      "generic_file_date_created" => "Date on which the object was created in its present form.",
      "generic_file_description" => "An abstract, notes about relationships between this object and other objects to which it is related, etc. detailing the object and its context.",
      "generic_file_identifier" => "A unique handle describing the resource in an external context, i.e. if it has an ISBN, OCLC number, or similar identifying numbers.",
      "generic_file_language" => "The language (if any) in which the resource is expressed; may be repeated.",
      "generic_file_publisher" => "The entity responsible for dissemination of the object, if it is different from the Creator. ScholarSphere assumes \"Pennsylvania State University Libraries\" if none is provided",
      "generic_file_rights" => "Any access restrictions or licensing agreements not already covered by the Public Access Statement."
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
require 'dil/rights_metadata'
require 'scholarsphere/permissions'
require 'psu/id_service'
require 'psu/noidify'
