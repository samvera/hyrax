# -*- encoding : utf-8 -*-
require 'rails/generators'

module Hydra
  class HeadGenerator < Rails::Generators::Base

    source_root File.expand_path('../templates', __FILE__)

    argument :model_name, type: :string , default: 'User'
    class_option :'skip-rspec', type: :boolean, default: false, desc: "Skip the rspec generator"


      desc """
    This generator makes the following changes to your application:
      1. Creates config/initializers/hydra_config.rb
      2. Creates config/fedora.yml and config/solr.yml which you may need to modify to tell the hydra head where to find fedora & solr
      3. Creates a number of role_map config files that are used in the placeholder user roles implementation
    Enjoy building your Hydra Head!
           """

    #
    # Config Files & Initializers
    #
      #
    def add_gems
      gem_group :development, :test do
        gem "fcrepo_wrapper"
        gem "rspec-rails" unless options[:'skip-rspec']
      end

      Bundler.with_clean_env do
        run "bundle install"
      end
    end

    def install_rspec
      return if options[:'skip-rspec']
      generate 'rspec:install'
    end

    def overwrite_catalog_controller
      copy_file "catalog_controller.rb", "app/controllers/catalog_controller.rb"
    end

    # Add Hydra to the application controller
    def inject_hydra_controller_behavior
      insert_into_file "app/controllers/application_controller.rb", after: "include Blacklight::Controller\n" do
        "  include Hydra::Controller::ControllerBehavior\n"
      end
    end

    # Copy all files in templates/config directory to host config
    def create_configuration_files

      # Initializers
      template "config/initializers/hydra_config.rb",
               "config/initializers/hydra_config.rb"

      # Role Mappings
      copy_file "config/role_map.yml", "config/role_map.yml"

      # CanCan ability.rb
      copy_file "ability.rb", "app/models/ability.rb"

      # Fedora & Solr YAML files
      invoke('active_fedora:config')

      copy_file 'config/blacklight.yml', force: true
    end

    def create_conneg_configuration
      file_path = "config/initializers/mime_types.rb"
      append_to_file file_path do
        "Mime::Type.register \"application/n-triples\", :nt\n" +
        "Mime::Type.register \"application/ld+json\", :jsonld\n" +
        "Mime::Type.register \"text/turtle\", :ttl"
      end
    end

    def inject_solr_document_conneg
      file_path = "app/models/solr_document.rb"
      if File.exists?(file_path)
        inject_into_file file_path, :before => /end\Z/ do
          "\n  # Do content negotiation for AF models. \n" +
          "\n  use_extension( Hydra::ContentNegotiation )\n"
        end
      end
    end

    # Add Hydra behaviors to the user model
    def inject_hydra_user_behavior
      file_path = "app/models/#{model_name.underscore}.rb"
      if File.exists?(file_path)
        inject_into_class file_path, model_name.classify do
          "  # Connects this user object to Hydra behaviors.\n" +
          "  include Hydra::User\n\n"
        end
      else
        puts "     \e[31mFailure\e[0m  Hydra requires a user object in order to apply access controls. This generators assumes that the model is defined in the file #{file_path}, which does not exist.  If you used a different name, please re-run the generator and provide that name as an argument. Such as \b  rails -g hydra:head client"
      end
    end
  end # HeadGenerator
end # Hydra
