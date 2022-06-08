# frozen_string_literal: true
require 'rails/generators'

class Hyrax::AssetsGenerator < Rails::Generators::Base
  desc """
    This generator installs the hyrax CSS assets into your application
       """

  source_root File.expand_path('../templates', __FILE__)

  def remove_blacklight_css
    remove_file "app/assets/stylesheets/blacklight.scss"
  end

  def inject_css
    copy_file "hyrax.scss", "app/assets/stylesheets/hyrax.scss"
  end

  def inject_js
    return if hyrax_javascript_installed?
    insert_into_file 'app/assets/javascripts/application.js', after: "//= require blacklight/blacklight\n" do
      "//= require hyrax\n" \
    end
  end

  def copy_image_file
    copy_file 'app/assets/images/unauthorized.png'
  end

  private

  def hyrax_javascript_installed?
    IO.read("app/assets/javascripts/application.js").include?('hyrax')
  end
end
