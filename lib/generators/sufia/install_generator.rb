require_relative 'abstract_migration_generator'

module Sufia
  class Install < Sufia::AbstractMigrationGenerator
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
     * Runs proxies generator
     * Runs cached stats generator
     * Runs ORCID field generator
     * Runs user stats generator
     * Runs upload_to_collection config generator
   3. Adds Sufia's abilities into the Ability class
   4. Adds controller behavior to the application controller
   5. Copies the catalog controller into the local app
   6. Adds Sufia::SolrDocumentBehavior to app/models/solr_document.rb
   7. Updates simple_form to use browser validations
   8. Installs Blacklight gallery
         """

    def banner
      say_status("info", "GENERATING SUFIA", :blue)
    end

    def run_required_generators
      generate "curation_concerns:install --skip-assets -f" unless options[:skip_curation_concerns]
    end

    def run_curation_concerns_work_generator
      say_status("info", "GENERATING DEFAULT GENERICWORK MODEL", :blue)
      generate 'curation_concerns:work GenericWork'
    end

    # Setup the database migrations
    def copy_migrations
      [
        "acts_as_follower_migration.rb",
        "add_social_to_users.rb",
        "add_ldap_attrs_to_user.rb",
        "add_avatars_to_users.rb",
        "create_local_authorities.rb",
        "create_trophies.rb",
        'add_linkedin_to_users.rb',
        'create_tinymce_assets.rb',
        'create_content_blocks.rb',
        'create_featured_works.rb',
        'add_external_key_to_content_blocks.rb',
        'create_uploaded_files.rb'
      ].each do |file|
        better_migration_template file
      end
    end

    def install_config
      generate "sufia:config"
    end

    # Add behaviors to the user model
    def inject_sufia_user_behavior
      file_path = "app/models/#{model_name.underscore}.rb"
      if File.exist?(file_path)
        inject_into_file file_path, after: /include CurationConcerns\:\:User.*$/ do
          "\n  # Connects this user object to Sufia behaviors." \
            "\n  include Sufia::User\n"
        end
      else
        puts "     \e[31mFailure\e[0m  Sufia requires a user object. This generators assumes that the model is defined in the file #{file_path}, which does not exist.  If you used a different name, please re-run the generator and provide that name as an argument. Such as \b  rails -g sufia client"
      end
    end

    def inject_sufia_work_behavior
      insert_into_file 'app/models/generic_work.rb', after: 'include ::CurationConcerns::BasicMetadata' do
        "\n  include Sufia::WorkBehavior" \
        "\n  self.human_readable_type = 'Work'"
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
      generate 'sufia:usagestats'
    end

    # Sets up proxies and transfers
    def proxies
      generate "sufia:proxies"
    end

    # Sets up cached usage stats
    def cached_stats
      generate 'sufia:cached_stats'
    end

    # Adds orcid field to user model
    def orcid_field
      generate 'sufia:orcid_field'
    end

    # Adds user stats-related migration & methods
    def user_stats
      generate 'sufia:user_stats'
    end

    # Sets up cached usage stats
    def cached_work_stats
      generate 'sufia:cached_work_stats'
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

    def use_blacklight_layout_theme
      file_path = "app/controllers/application_controller.rb"
      return unless File.exist?(file_path)
      gsub_file file_path, /with_themed_layout '1_column'/, "layout 'sufia-one-column'"
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

      routing_code = "\n  Hydra::BatchEdit.add_routes(self)\n" \
        "  # This must be the very last route in the file because it has a catch-all route for 404 errors.\n" \
        "  # This behavior seems to show up only in production mode.\n" \
        "  mount Sufia::Engine => '/'\n"

      sentinel = /end\Z/
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

    def inject_sufia_form
      file_path = "app/forms/curation_concerns/generic_work_form.rb"
      if File.exist?(file_path)
        gsub_file file_path, /CurationConcerns::Forms::WorkForm/, "Sufia::Forms::WorkForm"
        inject_into_file file_path, after: /model_class = ::GenericWork/ do
          "\n    self.terms += [:resource_type]\n"
        end
      else
        puts "     \e[31mFailure\e[0m  Sufia requires a GenericWorkForm object. This generator assumes that the model is defined in the file #{file_path}, which does not exist."
      end
    end

    def install_sufia_700
      generate "sufia:upgrade700"
    end

    def use_browser_validations
      gsub_file 'config/initializers/simple_form.rb',
                /browser_validations = false/,
                'browser_validations = true'
    end

    def install_blacklight_gallery
      generate "blacklight_gallery:install"
    end
  end
end
