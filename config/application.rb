# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'socket'
require 'sprockets'
require 'resolv'
require 'uri'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)
Bundler.require *Rails.groups(:assets => %w(development, test))
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

module ScholarSphere
  class Application < Rails::Application
    # Returns an array containing the vhost 'CoSign service' value and URL
    def get_vhost_by_host
      hostname = Socket.gethostname
      vhost = Rails.application.config.hosts_vhosts_map[hostname] || "https://#{hostname}/"
      service = URI.parse(vhost).host
      port = URI.parse(vhost).port
      service << "-#{port}" unless port == 443
      return [service, vhost]
    end
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
      :file_title => :title,
      :file_author => :creator
    }

    # Map hostnames onto Google Analytics tracking IDs
    config.ga_host_map = {
      'scholarsphere-test.dlt.psu.edu' => 'UA-33252017-1',
      'scholarsphere.psu.edu' => 'UA-33252017-2',
    }

    # Map hostnames onto vhosts
    config.hosts_vhosts_map = {
      'fedora1test' => 'https://scholarsphere-integration.dlt.psu.edu:8443/',
      'fedora2test' => 'https://scholarsphere-test.dlt.psu.edu/',
      'ss1stage' => 'https://scholarsphere-staging.dlt.psu.edu/',
      'ss2stage' => 'https://scholarsphere-staging.dlt.psu.edu/',
      'ss1prod' => 'https://scholarsphere.psu.edu/',
      'ss2prod' => 'https://scholarsphere.psu.edu/'
    }

    config.resource_types = {
      "Article" => "Article",
      "Audio" => "Audio",
      "Book" => "Book",
      "Capstone Project" => "Capstone Project",
      "Conference Proceeding" => "Conference Proceeding",
      "Dataset" => "Dataset",
      "Dissertation" => "Dissertation",
      "Image" => "Image",
      "Journal" => "Journal",
      "Map or Cartographic Material" => "Map or Cartographic Material",
      "Masters Thesis" => "Masters Thesis",
      "Part of Book" => "Part of Book",
      "Poster" => "Poster",
      "Presentation" => "Presentation",
      "Project" => "Project",
      "Report" => "Report",
      "Research Paper" => "Research Paper",
      "Software or Program Code" => "Software or Program Code",
      "Video" => "Video",
      "Other" => "Other",
    }

    config.public_permission_levels = {
      "Choose Access"=>"none",
      "View/Download" => "read"
    }

    config.permission_levels = {
      "Choose Access"=>"none",
      "View/Download" => "read",
      "Edit" => "edit"
    }

    config.owner_permission_levels = {
      "Edit" => "edit"
    }

    config.cc_licenses = {
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
      "generic_file_resource_type" => "Pre-defined categories to describe the type of file content being uploaded, such as \"article\" or \"dataset.\"  More than one type may be selected.",
      "generic_file_title" => "A name for the file to aid in identifying it. Defaults to the file name, though a more descriptive title is encouraged. <em>This is a required field</em>.", 
      "generic_file_tag" => "Words or phrases you select to describe what the file is about. These are used to search for content. <em>This is a required field</em>.",
      "generic_file_subject" => "Headings or index terms describing what the file is about; these <em>do</em> need to conform to an existing vocabulary. Currently ScholarSphere supports Library of Congress Subject Headings.",
      "generic_file_creator" => "The person or group responsible for the file being uploaded. Usually this is the author of the content. Personal names should be entered with the last name first, e.g. \"Smith, John.\" <em>This is a required field</em>.",
      "generic_file_related_url" => "A link to a website or other specific content (audio, video, PDF document) related to the file. An example is the URL of a research project from which the file was derived.", 
      "generic_file_based_near" => "A place name related to the file, such as its site of publication, or the city, state, or country the file's contents are about. Calls upon the GeoNames web service (<a href=\"http://www.geonames.org\">http://www.geonames.org</a>).",
      "generic_file_contributor" => "A person or group you want to recognize for playing a role in the creation of the file, but not the primary role. If there is a specific role you would like noted, include it in parentheses, e.g. \"Jones, Mary (advisor).\"",
      "generic_file_date_created" => "The date on which the file was generated. Dates are accepted in the form YYYY-MM-DD, e.g. 1776-07-04.",
      "generic_file_description" => "Free-text notes about the file itself. Examples include abstracts of a paper, citation information for a journal article, or a tag indicating a larger collection to which the file belongs.",
      "generic_file_identifier" => "A unique handle describing the file. An example would be a DOI for a journal article, or an ISBN or OCLC number for a book.",
      "generic_file_language" => " The language of the file content.",
      "generic_file_publisher" => "The person or group making the file available. Generally this is Penn State or the Penn State University Libraries.",
      "generic_file_rights" => "Licensing and distribution information governing access to the file. Select from the provided drop-down list. <em>This is a required field</em>."
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
require 'scholarsphere/utils'
