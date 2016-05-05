require 'rails/generators'
class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../spec/test_app_templates", __FILE__)

  def install_blacklight
    generate 'blacklight:install --devise'
  end

  # if you need to generate any additional configuration
  # into the test app, this generator will be run immediately
  # after setting up the application
  def install_engine
    generate 'hydra:head -f'
  end

  def copy_ip_config
    copy_file "config/hydra_ip_range.yml"
  end

  def copy_test_controlers
    copy_file "app/controllers/downloads_controller.rb"
  end
end
