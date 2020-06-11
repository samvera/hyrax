# frozen_string_literal: true
require 'rails/generators'

class Hyrax::ClamavGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc '
This generator makes the following changes to your application:
 1. Generates clamav initializer
       '

  def banner
    say_status('info', 'Generating clamav initializers', :blue)
  end

  def create_initializer_file
    copy_file 'config/clamav.rb', 'config/initializers/clamav.rb'
  end
end
