# frozen_string_literal: true
module Hyrax
  class Install < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    argument :model_name, type: :string, default: "user", desc: "Model name for User model (primarily passed to devise, but also used elsewhere)"

    class_option :'skip-riiif', type: :boolean, default: false, desc: "Skip generating RIIIF image service."

    class_option :'skip-health-check', type: :boolean, default: true, desc: "Generate the default health check endpoints."

    desc """
  This generator makes the following changes to your application:
  1. Runs installers for blacklight & hydra-head (which also install & configure devise)
  2. Runs hyrax:models:install
  3. Injects Hyrax routes
  4. Copies the catalog controller into the local app
  5. Adds Hyrax::SolrDocumentBehavior to app/models/solr_document.rb
  6. Adds local authority files to the application
  7. Copies modified simple_form initializers
  8. Generates a default workflow
  9. Installs model-related concerns
     * Creates several database migrations if they do not exist in /db/migrate
     * Adds user behavior to the user model
     * Creates the hyrax.rb configuration file
     * Generates mailboxer
  10. Adds Hyrax's abilities into the Ability class
  11. Adds controller behavior to the application controller
  12. Adds listener template and publisher initializer
  13. Copies the catalog controller into the local app
  14. Installs hyrax assets
  15. Updates simple_form to use browser validations
  16. Installs Blacklight gallery (and removes it's scss)
  17. Install jquery-datatables
  18. Initializes the noid-rails database-backed minter
  19. Generates RIIIF image server implementation
         """

    def run_required_generators
      say_status('info', '[Hyrax] GENERATING BLACKLIGHT', :blue)
      generate 'blacklight:install --devise'
      say_status('info', '[Hyrax] GENERATING HYDRA-HEAD', :blue)
      generate 'hydra:head -f'
      generate "hyrax:models#{options[:force] ? ' -f' : ''}"
      generate 'browse_everything:config'
    end

    def replace_blacklight_layout
      gsub_file 'app/controllers/application_controller.rb', /layout :determine_layout.+$/,
                "include Hyrax::ThemedLayoutController\n  with_themed_layout '1_column'\n"
    end

    def insert_builder
      insert_into_file 'app/models/search_builder.rb', after: /include Blacklight::Solr::SearchBuilderBehavior/ do
        "\n  # Add a filter query to restrict the search to documents the current user has access to\n"\
        "  include Hydra::AccessControlsEnforcement\n"\
        "  include Hyrax::SearchFilters\n"
      end
    end

    # The engine routes have to come after the devise routes so that /users/sign_in will work
    def inject_routes
      # Remove root route that was added by blacklight generator
      gsub_file 'config/routes.rb', /root (:to =>|to:) "catalog#index"/, ''

      inject_into_file 'config/routes.rb', after: /devise_for :users\s*\n/ do
        "  mount Qa::Engine => '/authorities'\n"\
        "  mount Hyrax::Engine, at: '/'\n"\
        "  resources :welcome, only: 'index'\n"\
        "  root 'hyrax/homepage#index'\n"\
        "  curation_concerns_basic_routes\n"\
      end
    end

    # Add behaviors to the SolrDocument model
    def inject_solr_document_behavior
      file_path = 'app/models/solr_document.rb'
      if File.exist?(file_path)
        inject_into_file file_path, after: /include Blacklight::Solr::Document.*$/ do
          "\n  # Adds Hyrax behaviors to the SolrDocument.\n" \
            "  include Hyrax::SolrDocumentBehavior\n"
        end
      else
        puts "     \e[31mFailure\e[0m  Hyrax requires a SolrDocument object. This generators assumes that the model is defined in the file #{file_path}, which does not exist."
      end
    end

    def create_workflow
      template('workflow.json.erb', "config/workflows/default_workflow.json")
      template('mediated_deposit_workflow.json.erb', "config/workflows/mediated_deposit_workflow.json")
    end

    def install_config
      generate "hyrax:config"
    end

    def install_mailboxer
      generate "mailboxer:install"
    end

    def configure_usage_stats
      copy_file 'config/analytics.yml', 'config/analytics.yml'
    end

    # we're going to inject this into the local app, so that it's easy to disable.
    def inject_ability
      inject_into_file 'app/models/ability.rb', after: /Hydra::Ability\s*\n/ do
        "  include Hyrax::Ability\n"\
        "  self.ability_logic += [:everyone_can_create_curation_concerns]\n\n"
      end
    end

    # add listener code to provide developers a hint that listening to events
    # is a good development pattern
    def inject_listeners
      generate "hyrax:listeners"
    end

    # Add behaviors to the application controller
    def inject_hyrax_application_controller_behavior
      file_path = "app/controllers/application_controller.rb"
      if File.exist?(file_path)
        insert_into_file file_path, after: /Hydra::Controller::ControllerBehavior\s*\n/ do
          "\n  # Adds Hyrax behaviors into the application controller" \
          "\n  include Hyrax::Controller\n"
        end
      else
        puts "     \e[31mFailure\e[0m  Could not find #{file_path}.  To add Hyrax behaviors to your Controllers, you must include the Hyrax::Controller module in the Controller class definition."
      end
    end

    def catalog_controller
      copy_file "catalog_controller.rb", "app/controllers/catalog_controller.rb"
    end

    def copy_helper
      copy_file 'hyrax_helper.rb', 'app/helpers/hyrax_helper.rb'
    end

    def qa_tables
      generate 'qa:local:tables'
    end

    def inject_required_seeds
      insert_into_file 'db/seeds.rb' do
        'Hyrax::RequiredDataSeeder.new.generate_seed_data'
      end
    end

    def install_assets
      generate "hyrax:assets"
    end

    def use_browser_validations
      gsub_file 'config/initializers/simple_form.rb',
                /browser_validations = false/,
                'browser_validations = true'
    end

    def install_blacklight_gallery
      generate "blacklight_gallery:install"
      # This was pulling in an extra copy of bootstrap, so we added the needed
      # includes to hyrax.scss
      remove_file 'app/assets/stylesheets/blacklight_gallery.css.scss'
    end

    def datatables
      javascript_manifest = 'app/assets/javascripts/application.js'
      insert_into_file javascript_manifest, after: /jquery.?\n/ do
        "//= require jquery.dataTables\n" \
        "//= require dataTables.bootstrap4\n"
      end

      insert_into_file 'app/assets/stylesheets/application.css', before: ' *= require_self' do
        " *= require dataTables.bootstrap4\n"
      end
    end

    def noid_rails_database_minter_initialize
      generate 'noid:rails:install'
    end

    def health_check
      generate 'hyrax:health_check' unless options[:'skip-health-check']
    end

    def riiif_image_server
      generate 'hyrax:riiif' unless options[:'skip-riiif']
    end

    def insert_env_queue_adapter
      insert_into_file 'config/application.rb', after: /config\.load_defaults [0-9.]+$/ do
        "\n    config.active_job.queue_adapter = ENV.fetch('HYRAX_ACTIVE_JOB_QUEUE') { 'async' }.to_sym\n"
      end
    end

    def universalviewer_files
      rake('hyrax:universal_viewer:install')
      rake('yarn:install')
    end

    def lando
      copy_file '.lando.yml'
    end

    def dotenv
      copy_file '.env'
      gem_group :development, :test do
        gem 'dotenv-rails', '~> 2.8'
      end
    end

    def support_analytics
      gem 'google-protobuf', force_ruby_platform: true # required because google-protobuf is not compatible with Alpine linux
      gem 'grpc', force_ruby_platform: true # required because grpc is not compatible with Alpine linux
    end
  end
end
