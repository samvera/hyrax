# -*- encoding : utf-8 -*-
require 'rails/generators'

class Sufia::ConfigGenerator < Rails::Generators::Base
  desc """
    This generator installs the sufia configuration files into your application for:
    * Sufia initializers
    * Citations
    * Admin stats
    * Mini-magick
    * TinyMCE
       """

  source_root File.expand_path('../templates', __FILE__)

  def create_initializer_config_file
    copy_file 'config/sufia.rb', 'config/initializers/sufia.rb'
  end

  # Add mini-magick configuration
  def minimagick_config
    copy_file 'config/mini_magick.rb', 'config/initializers/mini_magick.rb'
  end

  def tinymce_config
    copy_file "config/tinymce.yml", "config/tinymce.yml"
  end

  def inject_i18n
    copy_file "config/locales/sufia.en.yml", "config/locales/sufia.en.yml"
  end
end
