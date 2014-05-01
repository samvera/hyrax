require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root "../../spec/test_app_templates"

  def add_gems
    gem 'sufia-models', github: 'projecthydra/sufia', branch: 'dce_dev'
    # gem 'blacklight', ">= 5.4.0.rc1", "<6"
    # gem "blacklight-gallery", :github => 'projectblacklight/blacklight-gallery'
    # gem 'sir-trevor-rails', :github => 'sul-dlss/sir-trevor-rails'
    # gem 'openseadragon', :github => 'sul-dlss/openseadragon-rails'
    # gem "jettywrapper"
    Bundler.with_clean_env do
      run "bundle install"
    end
  end

  def run_blacklight_generator
    say_status("warning", "GENERATING BL", :yellow)

    generate 'blacklight:install', '--devise'
    say_status("warning", "GENERATING HYDRA-HEAD", :yellow)
    generate "hydra:head -f"
    say_status("warning", "GENERATING SUFIA", :yellow)
    generate "sufia:models:install#{options[:force] ? ' -f' : ''}"
  end

  def run_migrations
    # rake "spotlight:install:migrations"
    rake "db:migrate"
  end

  # def add_spotlight_routes_and_assets
  #   generate 'spotlight:install'
  # end

  # def add_mailer_defaults
  #   mail_config = "    config.action_mailer.default_url_options = { host: \"localhost:3000\", from: \"noreply@example.com\" }\n"
  #   insert_into_file 'config/application.rb', mail_config, after: "< Rails::Application\n"
  # end
end
