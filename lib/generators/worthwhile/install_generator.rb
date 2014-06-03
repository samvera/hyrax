require 'rails/generators'

module Worthwhile
  class Install < Rails::Generators::Base

    source_root File.expand_path('../templates', __FILE__)

    def run_blacklight_generator
      say_status("warning", "GENERATING BL", :yellow)
      generate 'blacklight:install', '--devise'

      say_status("warning", "GENERATING HYDRA-HEAD", :yellow)
      generate "hydra:head -f"

      say_status("warning", "GENERATING SUFIA", :yellow)
      generate "sufia:models:install#{options[:force] ? ' -f' : ''}"
    end

    def remove_catalog_controller
      say_status("warning", "Removing Blacklight's generated CatalogController...", :yellow)
      remove_file('app/controllers/catalog_controller.rb')
    end
    
    def inject_application_controller_behavior
      inject_into_file 'app/controllers/application_controller.rb', :after => /Blacklight::Controller\s*\n/ do
        "  include Worthwhile::ApplicationControllerBehavior\n"
      end
    end

    def inject_routes
      inject_into_file 'config/routes.rb', :after => /devise_for :users\s*\n/ do
        "  mount Hydra::Collections::Engine => '/'\n"\
        "  mount Worthwhile::Engine, at: '/'\n"\
        "  worthwhile_collections\n"\
        "  worthwhile_curation_concerns\n"\
        "  worthwhile_embargo_management\n"\
      end
    end

    def inject_ability
      inject_into_file 'app/models/ability.rb', :after => /Hydra::Ability\s*\n/ do
        "  include Worthwhile::Ability\n"\
        "  self.ability_logic += [:everyone_can_create_curation_concerns]\n\n"
      end
    end

    # Add behaviors to the SolrDocument model
    def inject_solr_document_behavior
      file_path = "app/models/solr_document.rb"
      if File.exists?(file_path)
        inject_into_file file_path, after: /include Blacklight::Solr::Document.*$/ do
          "\n  # Adds Worthwhile behaviors to the SolrDocument.\n" +
            "  include Worthwhile::SolrDocumentBehavior\n"
        end
      else
        puts "     \e[31mFailure\e[0m  Worthwhile requires a SolrDocument object. This generators assumes that the model is defined in the file #{file_path}, which does not exist."
      end
    end

    def assets
      copy_file "worthwhile.css.scss", "app/assets/stylesheets/worthwhile.css.scss"
      copy_file "worthwhile.js", "app/assets/javascripts/worthwhile.js"
    end

    def add_helper
      copy_file "worthwhile_helper.rb", "app/helpers/worthwhile_helper.rb"
      #inject_into_class 'app/helpers/application_helper.rb', ApplicationHelper, "  include WorthwhileHelper"
    end
    
    def add_config_file
      copy_file "worthwhile_config.rb", "config/initializers/worthwhile_config.rb"
    end
  end
end
