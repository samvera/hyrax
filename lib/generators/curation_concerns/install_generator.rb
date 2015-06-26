require 'rails/generators'

module CurationConcerns
  class Install < Rails::Generators::Base

    source_root File.expand_path('../templates', __FILE__)

    # BEGIN Blacklight Stuff
    # Really just relying on the blacklight generator to
    #   * set up devise
    #   * add solr.yml
    # ... so ultimately aiming to stop using it.
    def run_blacklight_generator
      say_status("warning", "GENERATING BL", :yellow)
      generate 'blacklight:install', '--devise'

      say_status("warning", "GENERATING HYDRA-HEAD", :yellow)
      generate "hydra:head -f"

      # TODO this should probably move to the hydra:head generator because it installs the gem
      say_status("warning", "GENERATING RSPEC-RAILS", :yellow)
      generate 'rspec:install'

      say_status("warning", "GENERATING CURATION_CONCERNS", :yellow)
      generate "curation_concerns:models:install#{options[:force] ? ' -f' : ''}"
    end

    def remove_catalog_controller
      say_status("warning", "Removing Blacklight's generated CatalogController...", :yellow)
      remove_file('app/controllers/catalog_controller.rb')
    end

    def inject_application_controller_behavior
      inject_into_file 'app/controllers/application_controller.rb', :after => /Blacklight::Controller\s*\n/ do
        "  include CurationConcerns::ApplicationControllerBehavior\n"
      end
    end

    def replace_blacklight_layout
      gsub_file 'app/controllers/application_controller.rb', /layout 'blacklight'/,
        "include CurationConcerns::ThemedLayoutController\n  with_themed_layout '1_column'\n"
    end

    def remove_blacklight_scss
      remove_file 'app/assets/stylesheets/blacklight.css.scss'
    end

    # END Blacklight stuff

    def inject_routes
      inject_into_file 'config/routes.rb', :after => /devise_for :users\s*\n/ do
        "  mount Hydra::Collections::Engine => '/'\n"\
        "  mount CurationConcerns::Engine, at: '/'\n"\
        "  curation_concerns_collections\n"\
        "  curation_concerns_basic_routes\n"\
        "  curation_concerns_embargo_management\n"\
      end
    end

    def inject_ability
      inject_into_file 'app/models/ability.rb', :after => /Hydra::Ability\s*\n/ do
        "  include CurationConcerns::Ability\n"\
        "  self.ability_logic += [:everyone_can_create_curation_concerns]\n\n"
      end
    end

    # Add behaviors to the SolrDocument model
    def inject_solr_document_behavior
      file_path = "app/models/solr_document.rb"
      if File.exists?(file_path)
        inject_into_file file_path, after: /include Blacklight::Solr::Document.*$/ do
          "\n  # Adds CurationConcerns behaviors to the SolrDocument.\n" +
            "  include CurationConcerns::SolrDocumentBehavior\n"
        end
      else
        puts "     \e[31mFailure\e[0m  CurationConcerns requires a SolrDocument object. This generators assumes that the model is defined in the file #{file_path}, which does not exist."
      end
    end

    def assets
      copy_file "curation_concerns.css.scss", "app/assets/stylesheets/curation_concerns.css.scss"
      copy_file "curation_concerns.js", "app/assets/javascripts/curation_concerns.js"
    end

    def add_helper
      copy_file "curation_concerns_helper.rb", "app/helpers/curation_concerns_helper.rb"
    end

    def add_collection_mixin
      inject_into_file 'app/models/collection.rb', after: /CurationConcerns::Collection.*$/ do
        "\n  include CurationConcerns::CollectionBehavior"
      end
      # inject_into_class 'app/models/collection.rb', Collection, "  include CurationConcerns::Collection"
    end

    def add_config_file
      copy_file "curation_concerns_config.rb", "config/initializers/curation_concerns_config.rb"
    end
  end
end
