require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root "./spec/test_app_templates"

  def add_gems
    gem 'hydra-editor', github: 'projecthydra-labs/hydra-editor', ref: '6a10e321ec'
    Bundler.with_clean_env do
      run "bundle install"
    end
  end

  def install_engine
    generate 'sufia:install', '-f'
  end

  def browse_everything_config
    generate "browse_everything:config"
  end

  def add_analytics_config
    append_file 'config/analytics.yml' do
      "\n" +
        "analytics:\n" +
        "  app_name: My App Name\n" +
        "  app_version: 0.0.1\n" +
        "  privkey_path: /tmp/privkey.p12\n" +
        "  privkey_secret: s00pers3kr1t\n" +
        "  client_email: oauth@example.org\n"
    end
  end

  def enable_analytics
    gsub_file "config/initializers/sufia.rb",
              "config.analytics = false", "config.analytics = true"
  end

  def add_sufia_assets
    insert_into_file 'app/assets/stylesheets/application.css', after: ' *= require_self' do
      "\n *= require sufia"
    end

    gsub_file 'app/assets/javascripts/application.js',
              '//= require_tree .', '//= require sufia'
  end

end
