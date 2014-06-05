require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root "../../spec/test_app_templates"

  def add_gems
    # gem 'sufia-models', github: 'projecthydra/sufia'
    # gem "jettywrapper"
    # pins to a version of hydra-access-controls with lease & embargo support
    #gem 'hydra-head', github:'projecthydra/hydra-head', ref:'b348f9f7e2f8103b8a8ec4c724dd9d9dc74b955d'
    gem 'hydra-head', github:'projecthydra/hydra-head', ref:'f241748'
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
