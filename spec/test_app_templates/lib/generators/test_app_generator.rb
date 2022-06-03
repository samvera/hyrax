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

  def add_valkyrie_migrations
    rake 'valkyrie_engine:install:migrations'
  end

  def create_collection_resource
    generate 'hyrax:collection_resource CollectionResource with_basic_metadata'

    gsub_file "config/metadata/collection_resource.yaml", "attributes: {}",
              <<-YAML

---
attributes:
  target_audience:
    type: string
    form:
      primary: true
      multiple: true
  department:
    type: string
    form:
      primary: true
  course:
    type: string
    form:
      primary: false
YAML

    # create the collection, but don't register it as 'the' collection
    gsub_file "config/initializers/hyrax.rb", /[^#] config.collection_model/, "  # config.collection_model"
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

  def create_work_resource
    generate 'hyrax:work_resource Monograph monograph_title:string'

    append_file 'config/metadata/monograph.yaml' do
      <<-YAML
  record_info:
    type: string
    form:
      required: true
      primary: true
  place_of_publication:
    type: string
    form:
      required: false
      primary: true
  genre:
    type: string
    form:
      primary: true
  series_title:
    type: string
    form:
      primary: false
  target_audience:
    type: string
    form:
      multiple: true
  table_of_contents:
    type: string
    form:
      multiple: false
  date_of_issuance:
    type: string
YAML
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
          google:
            analytics_id: UA-XXXXXXXX
            app_name: My App Name
            app_version: 0.0.1
            privkey_path: /tmp/privkey.p12
            privkey_secret: s00pers3kr1t
            client_email: oauth@example.org
          matomo:
            base_url: https://fake.example.com
            site_id: 5
            auth_token: 3123c4e9c98860aa240ffadcb98
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
    # raise '`yarn install` failed!' unless system('./bin/yarn install')
  end

  def create_sample_metadata_configuration
    copy_file 'sample_metadata.yaml', 'config/metadata/sample_metadata.yaml'
  end

  def add_valkyrie_test_adapter
    append_file 'spec/spec_helper.rb' do
      <<-CONFIG

require 'valkyrie'
Valkyrie::MetadataAdapter
  .register(Valkyrie::Persistence::Memory::MetadataAdapter.new, :test_adapter)
CONFIG
    end
  end
end
