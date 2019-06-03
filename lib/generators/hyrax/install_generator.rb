module Hyrax
  class Install < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    argument :model_name, type: :string, default: "user", desc: "Model name for User model (primarily passed to devise, but also used elsewhere)"

    class_option :'skip-riiif', type: :boolean, default: false, desc: "Skip generating RIIIF image service."

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
  12. Copies the catalog controller into the local app
  13. Installs hyrax assets
  14. Updates simple_form to use browser validations
  15. Installs Blacklight gallery (and removes it's scss)
  16. Install jquery-datatables
  17. Initializes the noid-rails database-backed minter
  18. Generates RIIIF image server implementation
         """

    def run_required_generators
      say_status('info', '[Hyrax] GENERATING BLACKLIGHT', :blue)
      generate 'blacklight:install --devise'
      say_status('info', '[Hyrax] GENERATING HYDRA-HEAD', :blue)
      generate 'hydra:head -f'
      generate "hyrax:models#{options[:force] ? ' -f' : ''}"
    end

    def replace_blacklight_layout
      gsub_file 'app/controllers/application_controller.rb', /layout 'blacklight'/,
                "include Hyrax::ThemedLayoutController\n  with_themed_layout '1_column'\n"
    end

    def insert_builder
      insert_into_file 'app/models/search_builder.rb', after: /include Hydra::AccessControlsEnforcement/ do
        "\n  include Hyrax::SearchFilters\n"
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

    def catalog_controller
      copy_file "catalog_controller.rb", "app/controllers/catalog_controller.rb"
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

    def copy_helper
      copy_file 'hyrax_helper.rb', 'app/helpers/hyrax_helper.rb'
    end

    def qa_tables
      generate 'qa:local:tables'
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
      # Generator is broken https://github.com/rweng/jquery-datatables-rails/issues/225
      # generate 'jquery:datatables:install bootstrap3'
      insert_into_file javascript_manifest, after: /jquery.?\n/ do
        "//= require jquery_ujs\n" \
        "//= require dataTables/jquery.dataTables\n" \
        "//= require dataTables/bootstrap/3/jquery.dataTables.bootstrap\n"
      end

      # This is only necessary for Rails 5.1 and hopefully is temporary.
      # There was some trouble getting the file-manager javascript (remote forms) to work well
      # with rails-ujs. Note jquery_ujs was added to the block above (after jQuery)
      gsub_file javascript_manifest, 'require rails-ujs', ''

      insert_into_file 'app/assets/stylesheets/application.css', before: ' *= require_self' do
        " *= require dataTables/bootstrap/3/jquery.dataTables.bootstrap\n"
      end
    end

    def noid_rails_database_minter_initialize
      generate 'noid:rails:install'
    end

    def riiif_image_server
      generate 'hyrax:riiif' unless options[:'skip-riiif']
    end

    def universalviewer_files
      rake('hyrax:universal_viewer:install')
    end

    # Blacklight::Controller will by default add an after_action filter to discard all flash messages on xhr requests.
    # This has caused problems when we perform a post-redirect-get cycle using xhr and turbolinks.
    # This injector will modify the generated ApplicationController to skip this action.
    # TODO: This may be removed in Blacklight 7.x, so we'll likely need to remove this after updating.
    def inject_skip_blacklilght_flash_discarding
      insert_into_file "app/controllers/application_controller.rb", after: "include Blacklight::Controller\n" do
        "  skip_after_action :discard_flash_if_xhr\n"
      end
    end
  end
end
