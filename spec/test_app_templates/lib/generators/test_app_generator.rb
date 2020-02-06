require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  # Generator is executed from /path/to/hyrax/.internal_test_app/lib/generators/test_app_generator/
  # so the following path gets us to /path/to/hyrax/spec/test_app_templates/
  source_root File.expand_path('../../../../spec/test_app_templates/', __FILE__)

  def conditional_postgresql_for_ci_environment
    # For now, postgresql is something we are looking at adding to CircleCI
    # as such, don't poke around with that configuration unless we are in a
    # CI run environment
    return true unless ENV['CI']
    db_config = Psych.load(File.read("config/database.yml"))
    # We are looking for the "internal_test" database name, which means
    # EngineCart built the internal app using the "--database=postgresql"
    # switch (see `.circleci/config.yml` with nested key:
    #   jobs > build > environment > ENGINE_CART_RAILS_OPTIONS
    # )
    return true unless db_config.fetch("default").fetch("adapter") == 'postgresql'
    content = <<-EOS.strip_heredoc
              # WARNING:
              #   This config/database.yml is currently intended for CircleCI
              #   test runs. It _might_ work locally, but that is not its
              #   current purpose.
              #
              # This config/database.yml was generated from the following file:
              #   #{__FILE__}
              #
              # By default, we have top-level keys of "default", "test",
              # "development", and "production". In the YAML file, "default"
              # establishes parameters that are inherited by the other
              # environments. However we've built you a custom config/database.yml
              # so you don't need the "default".
              #
              # Similarly, we are building a test application run by CI (or developers).
              # Therefore, you don't need a production environment.
              #
              # NOTE:
              #   The development and test environments look very similar. This is by
              #   design. Yes, they are likely to have the same database name. That's
              #   okay. You, developer, wouldn't want that if you were running the
              #   internal test app on your machine; After all the test environment
              #   cleans itself up after each test; Not ideal for local development.
              development:
                adapter: postgresql
                encoding: unicode
                pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
                database: <%= ENV.fetch("POSTGRES_DB") { 'internal_development' } %>
                <% if ENV["POSTGRES_HOST"]%>host: <%= ENV["POSTGRES_HOST"] %><% end %>
                <% if ENV["POSTGRES_USER"]%>user: <%= ENV["POSTGRES_USER"] %><% end %>
              test:
                adapter: postgresql
                encoding: unicode
                pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
                database: <%= ENV.fetch("POSTGRES_DB") { 'internal_test' } %>
                <% if ENV["POSTGRES_HOST"]%>host: <%= ENV["POSTGRES_HOST"] %><% end %>
                <% if ENV["POSTGRES_USER"]%>user: <%= ENV["POSTGRES_USER"] %><% end %>
              EOS

    File.open("config/database.yml", "w+") do |f|
      f.puts content
    end

    rake "db:create:all"
    rake "db:test:prepare"
  end

  def install_engine
    generate 'hyrax:install', '-f'
  end


  def browse_everything_install
    generate "browse_everything:install --skip-assets"
  end

  def create_generic_work
    generate 'hyrax:work GenericWork'
  end

  def create_nested_work
    generate 'hyrax:work NamespacedWorks::NestedWork'
    gsub_file 'app/models/namespaced_works/nested_work.rb',
              'include ::Hyrax::WorkBehavior',
              <<-EOS.strip_heredoc
                property :created, predicate: ::RDF::Vocab::DC.created, class_name: TimeSpan
                  include ::Hyrax::WorkBehavior
              EOS

    gsub_file 'app/models/namespaced_works/nested_work.rb',
              'include ::Hyrax::BasicMetadata',
              <<-EOS.strip_heredoc
                include ::Hyrax::BasicMetadata
                  accepts_nested_attributes_for :created
              EOS
  end

  def create_time_span
    create_file 'app/models/time_span.rb' do
      <<-EOS.strip_heredoc
      class TimeSpan < ActiveTriples::Resource
        def initialize(uri = RDF::Node.new, _parent = ActiveTriples::Resource.new)
          uri = if uri.try(:node?)
                  RDF::URI(\"#timespan_\#{uri.to_s.gsub('_:', '')}\")
                elsif uri.to_s.include?('#')
                  RDF::URI(uri)
                end
          super
        end

        def persisted?
          !new_record?
        end

        def new_record?
          id.start_with?('#')
        end

        configure type: ::RDF::Vocab::EDM.TimeSpan
        property :start, predicate: ::RDF::Vocab::EDM.begin
        property :finish, predicate: ::RDF::Vocab::EDM.end
      end
      EOS
    end
  end

  def create_work
    generate 'hyrax:work_resource Monograph monograph_title:string'
  end

  def banner
    say_status("info", "ADDING OVERRIDES FOR TEST ENVIRONMENT", :blue)
  end

  def comment_out_web_console
    gsub_file "Gemfile",
              "gem 'web-console'", "# gem 'web-console'"
  end

  def add_analytics_config
    append_file 'config/analytics.yml' do
      <<-EOS.strip_heredoc
        analytics:
          app_name: My App Name
          app_version: 0.0.1
          privkey_path: /tmp/privkey.p12
          privkey_secret: s00pers3kr1t
          client_email: oauth@example.org
      EOS
    end
  end

  def enable_analytics
    gsub_file "config/initializers/hyrax.rb",
              "# config.analytics = false", "config.analytics = true"
  end

  def enable_riiif_image_server
    gsub_file "config/initializers/hyrax.rb",
              "# config.iiif_image_server = false", "config.iiif_image_server = true"
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

  def disable_animations_for_more_reliable_feature_specs
    inject_into_file 'config/environments/test.rb', after: "Rails.application.configure do\n" do
      "  config.middleware.use DisableAnimationsInTestEnvironment\n"
    end
    copy_file 'disable_animations_in_test_environment.rb', 'app/middleware/disable_animations_in_test_environment.rb'
  end

  def configure_action_cable_to_use_redis
    gsub_file 'config/cable.yml',
              "development:\n  adapter: async",
              "development:\n  adapter: redis\n  url: redis://localhost:6379"
  end

  def install_universal_viewer
    raise '`yarn install` failed!' unless system('./bin/yarn install')
  end

  def create_sample_metadata_configuration
    copy_file 'sample_metadata.yaml', 'config/metadata/sample_metadata.yaml'
  end
end
