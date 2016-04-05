require 'rails/generators'

module CurationConcerns
  class Install < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    argument :model_name, type: :string, default: 'user'
    class_option :'skip-assets', type: :boolean, default: false, desc: "Skip generating javascript and css assets into the application"

    desc 'This generator makes the following changes to your application:
   1. Runs installers for blacklight & hydra-head (which also install & configure devise)
   2. Runs curation_concerns:models:install
   3. Adds controller behavior to the application controller
   4. Injects CurationConcerns routes
   5. Adds CurationConcerns abilities into the Ability class
   6. Copies the catalog controller into the local app
   7. Adds CurationConcerns::SolrDocumentBehavior to app/models/solr_document.rb
   8. Adds config/authorities/rights.yml to the application
   9. Adds config/authorities/resource_types.yml to the application
         '

    def run_required_generators
      say_status('warning', '[CurationConcerns] GENERATING BLACKLIGHT', :yellow)
      generate 'blacklight:install --devise'
      say_status('warning', '[CurationConcerns] GENERATING HYDRA-HEAD', :yellow)
      generate 'hydra:head -f'
      say_status('warning', '[CurationConcerns] GENERATING CURATION_CONCERNS MODELS', :yellow)
      generate "curation_concerns:models#{options[:force] ? ' -f' : ''}"
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
        "\n  include CurationConcerns::SearchFilters\n"
      end
    end

    def inject_routes
      # Remove root route that was added by blacklight generator
      gsub_file 'config/routes.rb', /root (:to =>|to:) "catalog#index"/, ''

      inject_into_file 'config/routes.rb', after: /devise_for :users\s*\n/ do
        "  mount Hydra::Collections::Engine => '/'\n"\
        "  mount CurationConcerns::Engine, at: '/'\n"\
        "  resources :welcome, only: 'index'\n"\
        "  root 'welcome#index'\n"\
        "  curation_concerns_collections\n"\
        "  curation_concerns_basic_routes\n"\
        "  curation_concerns_embargo_management\n"\
      end
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
          "\n  # Adds CurationConcerns behaviors to the SolrDocument.\n" \
            "  include CurationConcerns::SolrDocumentBehavior\n"
        end
      else
        puts "     \e[31mFailure\e[0m  CurationConcerns requires a SolrDocument object. This generators assumes that the model is defined in the file #{file_path}, which does not exist."
      end
    end

    def assets
      generate 'curation_concerns:assets' unless options[:'skip-assets']
    end

    def add_helper
      copy_file 'curation_concerns_helper.rb', 'app/helpers/curation_concerns_helper.rb'
    end

    def rights_config
      copy_file "config/authorities/rights.yml", "config/authorities/rights.yml"
    end

    def resource_types_config
      copy_file "config/authorities/resource_types.yml", "config/authorities/resource_types.yml"
    end
  end
end
