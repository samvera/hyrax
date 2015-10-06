require 'rails/generators'

class Sufia::Models::MinimagickConfigGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc """
This Generator makes the following changes to your application:
  1. Creates new mini_magick.rb initializer configuring use of posix-spawn
       """

  def banner
    say_status("info", "ADDING MINIMAGICK CONFIG", :blue)
  end

  def create_configuration_file
    copy_file 'config/mini_magick.rb', 'config/initializers/mini_magick.rb'
  end
end
