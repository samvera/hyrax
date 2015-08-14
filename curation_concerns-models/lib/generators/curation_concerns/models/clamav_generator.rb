# -*- encoding : utf-8 -*-
require 'rails/generators'

class CurationConcerns::Models::ClamavGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc ''"
This generator makes the following changes to your application:
 1. Generates clamav initializer
       "''

  def banner
    say_status('info', 'Generating clamav initializers', :blue)
  end

  def create_initializer_file
    copy_file 'config/clamav.rb', 'config/initializers/clamav.rb'
  end
end
