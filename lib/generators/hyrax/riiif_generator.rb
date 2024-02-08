# frozen_string_literal: true
require 'rails/generators'

class Hyrax::RiiifGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  desc '
    This generator makes the following changes to your application:
      1. Adds riiif dependency to application Gemfile
      2. Copies riiif initializer to application
      3. Mounts riiif engine within application
      4. Overrides Hyrax config variables to use riiif for image and info URLs
      5. Copies 404 image for riiif unauthorized responses'

  def banner
    say_status('info', 'GENERATING RIIIF IMAGE SERVER', :blue)
  end

  def add_to_gemfile
    gem 'riiif', '~> 2.1'
  end

  def copy_initializer
    copy_file 'config/initializers/riiif.rb'
  end

  def mount_route
    route "mount Riiif::Engine => 'images', as: :riiif if Hyrax.config.iiif_image_server?"
  end

  def enable_riiif_in_hyrax_config
    insert_into_file 'config/initializers/hyrax.rb', before: /^  # config.iiif_image_server = false/ do
      "  config.iiif_image_server = true\n"
    end
  end

  def override_image_url_builder_in_hyrax_config
    insert_into_file 'config/initializers/hyrax.rb', before: /^  # config.iiif_image_url_builder/ do
      "  config.iiif_image_url_builder = lambda do |file_id, base_url, size, format|\n" \
      "    Riiif::Engine.routes.url_helpers.image_url(file_id, host: base_url, size: size)\n" \
      "  end\n"
    end
  end

  def override_info_url_builder_in_hyrax_config
    insert_into_file 'config/initializers/hyrax.rb', before: /^  # config.iiif_info_url_builder/ do
      "  config.iiif_info_url_builder = lambda do |file_id, base_url|\n" \
      "    uri = Riiif::Engine.routes.url_helpers.info_url(file_id, host: base_url)\n" \
      "    uri.sub(%r{/info\\.json\\Z}, '')\n" \
      "  end\n"
    end
  end

  def copy_unauthorized_image
    copy_file 'app/assets/images/us_404.svg'
  end
end
