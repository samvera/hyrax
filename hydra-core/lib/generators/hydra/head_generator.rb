# -*- encoding : utf-8 -*-
require 'rails/generators'

module Hydra
  class HeadGenerator < Rails::Generators::Base

    source_root File.expand_path('../templates', __FILE__)

    argument :model_name, :type => :string , :default => "user"
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

    def inject_test_framework
      return if options[:'skip-rspec']

      application("\n" <<
        "    config.generators do |g|\n" <<
        "      g.test_framework :rspec, :spec => true\n" <<
        "    end\n\n"
      )

      gem_group :development, :test do
        gem "rspec-rails"
        gem 'jettywrapper'
      end

      Bundler.with_clean_env do
        run "bundle install"
      end
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
      file_path = "config/initializers/hydra_config.rb"
      copy_file "config/initializers/hydra_config.rb", file_path
      unless model_name == 'user'
        insert_into_file file_path, :after => 'Hydra.configure do |config|' do
            "\n  config.user_model = '#{model_name.classify}'"
        end
      end

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
      inject_into_file file_path, :before => /\Z/  do
        "\nMime::Type.register \"application/n-triples\", :nt" + 
        "\nMime::Type.register \"application/json\", :jsonld" +
        "\nMime::Type.register \"text/turtle\", :ttl"
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
