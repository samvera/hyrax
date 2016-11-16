module Sufia
  class Install < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)
    argument :model_name, type: :string, default: "user", desc: "Model name for User model (primarily passed to devise, but also used elsewhere)"
    class_option :skip_curation_concerns, type: :boolean, default: false, desc: "whether to skip the curation_concerns:models installer"
    desc """
  This generator makes the following changes to your application:
   1. Runs curation_concerns:install
   2. Installs model-related concerns
     * Creates several database migrations if they do not exist in /db/migrate
     * Adds user behavior to the user model
     * Generates GenericWork model.
     * Creates the sufia.rb configuration file
     * Generates mailboxer
   3. Adds Sufia's abilities into the Ability class
   4. Adds controller behavior to the application controller
   5. Copies the catalog controller into the local app
   6. Adds Sufia::SolrDocumentBehavior to app/models/solr_document.rb
   7. Installs sufia assets
   8. Installs hydra:batch_edit
   9. Updates simple_form to use browser validations
   10. Installs Blacklight gallery (and removes it's scss)
   11. Runs the jquery-datatables generator
         """

    def banner
      say_status("info", "GENERATING SUFIA", :blue)
    end

    def run_required_generators
      generate "curation_concerns:install --skip-assets -f" unless options[:skip_curation_concerns]
    end

    # Setup the database migrations
    def copy_migrations
      rake 'sufia:install:migrations'
    end

    def install_config
      generate "sufia:config"
    end

    # Add behaviors to the user model
    def inject_sufia_user_behaviors
      file_path = "app/models/#{model_name.underscore}.rb"
      if File.exist?(file_path)
        inject_into_file file_path, after: /include CurationConcerns\:\:User.*$/ do
          "\n  # Connects this user object to Sufia behaviors." \
          "\n  include Sufia::User" \
          "\n  include Sufia::UserUsageStats\n"
        end
      else
        puts "     \e[31mFailure\e[0m  Sufia requires a user object. This generators assumes that the model is defined in the file #{file_path}, which does not exist.  If you used a different name, please re-run the generator and provide that name as an argument. Such as \b  rails -g sufia:install client"
      end
    end

    def inject_sufia_file_set_behavior
      insert_into_file 'app/models/file_set.rb', after: 'include ::CurationConcerns::FileSetBehavior' do
        "\n  include Sufia::FileSetBehavior"
      end
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

    def catalog_controller
      copy_file "catalog_controller.rb", "app/controllers/catalog_controller.rb"
    end

    def copy_helper
      copy_file 'sufia_helper.rb', 'app/helpers/sufia_helper.rb'
    end

    # The engine routes have to come after the devise routes so that /users/sign_in will work
    def inject_routes
      gsub_file 'config/routes.rb', /root (:to =>|to:) "catalog#index"/, ''
      gsub_file 'config/routes.rb', /'welcome#index'/, "'sufia/homepage#index'" # Replace the root path injected by CurationConcerns
      routing_code = "\n  mount Sufia::Engine, at: '/'\n"
      sentinel = /\s+mount CurationConcerns::Engine/
      inject_into_file 'config/routes.rb', routing_code, before: sentinel, verbose: false
    end

    # Add behaviors to the SolrDocument model
    def inject_sufia_solr_document_behavior
      file_path = "app/models/solr_document.rb"
      if File.exist?(file_path)
        inject_into_file file_path, after: /include CurationConcerns::SolrDocumentBehavior/ do
          "\n  # Adds Sufia behaviors to the SolrDocument.\n" \
            "  include Sufia::SolrDocumentBehavior\n"
        end
      else
        puts "     \e[31mFailure\e[0m  Sufia requires a SolrDocument object. This generator assumes that the model is defined in the file #{file_path}, which does not exist."
      end
    end

    def install_sufia_700
      generate "sufia:upgrade700"
    end

    def install_assets
      generate "sufia:assets"
    end

    def install_batch_edit
      generate "hydra_batch_edit:install"
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

    def create_workflow
      template('workflow.json.erb', "config/workflows/one_step_mediated_deposit_workflow.json")
    end
  end
end
