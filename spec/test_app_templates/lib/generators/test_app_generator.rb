require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root "../../spec/test_app_templates"

  def install_engine
    generate 'curation_concerns:install'
  end

  def run_migrations
    rake "db:migrate"
  end
end
