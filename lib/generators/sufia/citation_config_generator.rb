require 'rails/generators'

class Sufia::CitationConfigGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc """
This Generator makes the following changes to your application:
  1. Updates existing sufia.rb initializer to include a citation configuration
       """

  def banner
    say_status("info", "ADDING CITATIONS OPTION TO SUFIA CONFIG", :blue)
  end

  def inject_config_initializer
    inject_into_file 'config/initializers/sufia.rb', before: "# Where to store tempfiles, leave blank for the system temp directory (e.g. /tmp)" do
      "# Enables a link to the citations page for a generic_file.\n" \
        "# Default is false\n" \
        "# config.citations = false\n"
    end
  end
end
