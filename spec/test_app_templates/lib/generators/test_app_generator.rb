require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  # Generator is executed from /path/to/hyrax/.internal_test_app/lib/generators/test_app_generator/
  # so the following path gets us to /path/to/hyrax/spec/test_app_templates/
  source_root File.expand_path('../../../../spec/test_app_templates/', __FILE__)

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
end
