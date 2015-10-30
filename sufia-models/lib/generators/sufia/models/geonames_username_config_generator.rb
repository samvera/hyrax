require 'rails/generators'

class Sufia::Models::GeonamesUsernameConfigGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc """
This Generator makes the following changes to your application:
  1. Updates existing sufia.rb initializer to include a geonames_username configuration
       """

  def banner
    say_status("info", "ADDING GEONAMES_USERNAME OPTION TO SUFIA CONFIG", :blue)
  end

  def inject_config_initializer
    inject_into_file 'config/initializers/sufia.rb', before: "# Where to store tempfiles, leave blank for the system temp directory (e.g. /tmp)" do
      "config.geonames_username = ''\n"
    end
  end
end
