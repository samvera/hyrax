require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root "../../spec/test_app_templates"

  # def add_gems
  #   gem 'sufia-models', github: 'projecthydra/sufia'
  #   Bundler.with_clean_env do
  #     run "bundle install"
  #   end
  # end

  def run_generator
    generate 'curation_concerns:install'
  end

  def run_migrations
    rake "db:migrate"
  end
end
