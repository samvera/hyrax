require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root "./spec/test_app_templates"

  def install_engine
    generate 'hyrax:install', '-f'
  end

  def create_generic_work
    generate 'hyrax:work GenericWork'
  end

  def create_atlas_work
    # ActiveSupport interprets "atlas" as plural which causes
    # counter-intuitive route paths. Add an inflection to correct
    # these paths
    append_file 'config/initializers/inflections.rb' do
      "ActiveSupport::Inflector.inflections(:en) do |inflect|\n" \
      "  inflect.irregular 'atlas', 'atlases'\n" \
      "end\n"
    end
    generate 'hyrax:work RareBooks/Atlas'
  end

  def comment_out_web_console
    gsub_file "Gemfile",
              "gem 'web-console'", "# gem 'web-console'"
  end

  def browse_everything_install
    generate "browse_everything:install --skip-assets"
  end

  def banner
    say_status("info", "ADDING OVERRIDES FOR TEST ENVIRONMENT", :blue)
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
    gsub_file "config/initializers/hyrax.rb",
              "config.analytics = false", "config.analytics = true"
  end

  def enable_i18n_translation_errors
    gsub_file "config/environments/development.rb",
              "# config.action_view.raise_on_missing_translations = true", "config.action_view.raise_on_missing_translations = true"
    gsub_file "config/environments/test.rb",
              "# config.action_view.raise_on_missing_translations = true", "config.action_view.raise_on_missing_translations = true"
  end

  def enable_arkivo_api
    generate 'hyrax:arkivo_api'
  end

  def relax_routing_constraint
    gsub_file 'config/initializers/arkivo_constraint.rb', 'false', 'true'
  end
end
