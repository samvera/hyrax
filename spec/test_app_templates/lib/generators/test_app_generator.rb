require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root "../../spec/test_app_templates"

  def add_gems
    # gem 'sufia-models', github: 'projecthydra/sufia'
    # gem "jettywrapper"
    # pins to a version of hydra-access-controls with lease & embargo support
    gem 'hydra-head', '7.1.0.rc1'
    Bundler.with_clean_env do
      run "bundle install"
    end
  end

  def run_generator
    generate 'worthwhile:install'
  end

  def run_migrations
    rake "db:migrate"
  end
end
