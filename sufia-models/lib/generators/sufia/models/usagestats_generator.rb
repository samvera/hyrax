# -*- encoding : utf-8 -*-
require 'rails/generators'

class Sufia::Models::UsagestatsGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc """
This generator makes the following changes to your application:
 1. Generates usage stats config
       """

  def banner
    say_status("info", "GENERATING SUFIA USAGE STATS", :blue)
  end

  def create_configuration_file
    copy_file 'config/analytics.yml', 'config/analytics.yml'
  end
end
