module Sufia
  class Install < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    argument :model_name, type: :string, default: "user", desc: "Model name for User model (primarily passed to devise, but also used elsewhere)"
    desc """
  This generator makes the following changes to your application:
  1. Runs installers for blacklight & hydra-head (which also install & configure devise)
  2. Runs curation_concerns:models:install
  3. Adds controller behavior to the application controller
  4. Injects CurationConcerns routes
  5. Adds CurationConcerns abilities into the Ability class
  6. Copies the catalog controller into the local app
  7. Adds Sufia::SolrDocumentBehavior to app/models/solr_document.rb
  8. Adds local authority files to the application
  9. Copies modified simple_form initializers
  10. Generates a default workflow
  11. Installs model-related concerns
     * Creates several database migrations if they do not exist in /db/migrate
     * Adds user behavior to the user model
     * Generates GenericWork model.
     * Creates the sufia.rb configuration file
     * Generates mailboxer
  12. Adds Sufia's abilities into the Ability class
  13. Adds controller behavior to the application controller
  14. Copies the catalog controller into the local app
  15. Installs sufia assets
  16. Updates simple_form to use browser validations
  17. Installs Blacklight gallery (and removes it's scss)
  18. Runs the jquery-datatables generator
         """

    def run_required_generators
      say_status('warning', '[Sufia] GENERATING BLACKLIGHT', :yellow)
      generate 'blacklight:install --devise'
      say_status('warning', '[Sufia] GENERATING HYDRA-HEAD', :yellow)
      generate 'hydra:head -f'
      say_status('warning', '[Sufia] GENERATING MODELS', :yellow)
      generate "sufia:models#{options[:force] ? ' -f' : ''}"
      say_status('warning', '[Sufia] GENERATING ADMIN DASHBOARD', :yellow)
      generate "sufia:admin_dashboard#{options[:force] ? ' -f' : ''}"
    end

    def inject_application_controller_behavior
      inject_into_file 'app/controllers/application_controller.rb', after: /Hydra::Controller::ControllerBehavior\s*\n/ do
        "\n  # Adds CurationConcerns behaviors to the application controller.\n" \
        "  include CurationConcerns::ApplicationControllerBehavior\n"
      end
    end

    def replace_blacklight_layout
      gsub_file 'app/controllers/application_controller.rb', /layout 'blacklight'/,
                "include CurationConcerns::ThemedLayoutController\n  with_themed_layout '1_column'\n"
    end

    def insert_builder
      insert_into_file 'app/models/search_builder.rb', after: /include Hydra::AccessControlsEnforcement/ do
        "\n  include Sufia::SearchFilters\n"
      end
    end

    # The engine routes have to come after the devise routes so that /users/sign_in will work
    def inject_routes
      # Remove root route that was added by blacklight generator
      gsub_file 'config/routes.rb', /root (:to =>|to:) "catalog#index"/, ''

      inject_into_file 'config/routes.rb', after: /devise_for :users\s*\n/ do
        "  mount CurationConcerns::Engine, at: '/'\n"\
        "  resources :welcome, only: 'index'\n"\
        "  root 'welcome#index'\n"\
        "  curation_concerns_collections\n"\
        "  curation_concerns_basic_routes\n"\
        "  curation_concerns_embargo_management\n"\
      end
      gsub_file 'config/routes.rb', /root (:to =>|to:) "catalog#index"/, ''
      gsub_file 'config/routes.rb', /'welcome#index'/, "'sufia/homepage#index'" # Replace the root path injected by CurationConcerns
      routing_code = "\n  mount Sufia::Engine, at: '/'\n"
      sentinel = /\s+mount CurationConcerns::Engine/
      inject_into_file 'config/routes.rb', routing_code, before: sentinel, verbose: false
    end

    def inject_ability
      inject_into_file 'app/models/ability.rb', after: /Hydra::Ability\s*\n/ do
        "  include CurationConcerns::Ability\n"\
        "  self.ability_logic += [:everyone_can_create_curation_concerns]\n\n"
      end
    end

    def catalog_controller
      copy_file "catalog_controller.rb", "app/controllers/catalog_controller.rb"
    end

    # Add behaviors to the SolrDocument model
    def inject_solr_document_behavior
      file_path = 'app/models/solr_document.rb'
      if File.exist?(file_path)
        inject_into_file file_path, after: /include Blacklight::Solr::Document.*$/ do
          "\n  # Adds Sufia behaviors to the SolrDocument.\n" \
            "  include Sufia::SolrDocumentBehavior\n"
        end
      else
        puts "     \e[31mFailure\e[0m  Sufia requires a SolrDocument object. This generators assumes that the model is defined in the file #{file_path}, which does not exist."
      end
    end

    def assets
      generate 'curation_concerns:assets' unless options[:'skip-assets']
    end

    def add_helper
      copy_file 'curation_concerns_helper.rb', 'app/helpers/curation_concerns_helper.rb'
    end

    def create_workflow
      template('workflow.json.erb', "config/workflows/default_workflow.json")
      template('mediated_deposit_workflow.json.erb', "config/workflows/mediated_deposit_workflow.json")
    end

    def install_config
      generate "sufia:config"
    end

    def install_mailboxer
      generate "mailboxer:install"
    end

    def configure_usage_stats
      copy_file 'config/analytics.yml', 'config/analytics.yml'
    end

    def insert_abilities
      insert_into_file 'app/models/ability.rb', after: /CurationConcerns::Ability/ do
        "\n  include Sufia::Ability\n"
      end
    end

    # Add behaviors to the application controller
    def inject_sufia_application_controller_behavior
      file_path = "app/controllers/application_controller.rb"
      if File.exist?(file_path)
        insert_into_file file_path, after: 'CurationConcerns::ApplicationControllerBehavior' do
          "  \n  # Adds Sufia behaviors into the application controller \n" \
          "  include Sufia::Controller\n"
        end
      else
        puts "     \e[31mFailure\e[0m  Could not find #{file_path}.  To add Sufia behaviors to your Controllers, you must include the Sufia::Controller module in the Controller class definition."
      end
    end

    def copy_helper
      copy_file 'sufia_helper.rb', 'app/helpers/sufia_helper.rb'
    end

    def install_sufia_700
      generate "sufia:upgrade700"
    end

    def install_assets
      generate "sufia:assets"
    end

    def use_browser_validations
      gsub_file 'config/initializers/simple_form.rb',
                /browser_validations = false/,
                'browser_validations = true'
    end

    def install_blacklight_gallery
      generate "blacklight_gallery:install"
      # This was pulling in an extra copy of bootstrap, so we added the needed
      # includes to sufia.scss
      remove_file 'app/assets/stylesheets/blacklight_gallery.css.scss'
    end

    def datatables
      generate 'jquery:datatables:install bootstrap3'
    end
  end
end
