# -*- encoding : utf-8 -*-
require 'rails/generators'
require 'rails/generators/migration'

module Hydra
class HeadGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)

  argument     :model_name, :type => :string , :default => "user"

    desc """
  This generator makes the following changes to your application:
    1. Creates a database migration for superusers if they do not exist in /db/migrate
    2. Adds additional mime types to you application in the file '/config/initializers/mime_types.rb'
    3. Creates config/initializers/hydra_config.rb
    4. Creates config/fedora.yml and config/solr.yml which you may need to modify to tell the hydra head where to find fedora & solr
    5. Creates a number of role_map config files that are used in the placeholder user roles implementation
  Enjoy building your Hydra Head!
         """

  #
  # Config Files & Initializers
  #

  def inject_test_framework
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

  # Copy all files in templates/config directory to host config
  def create_configuration_files
    copy_file "catalog_controller.rb", "app/controllers/catalog_controller.rb"

    # Initializers
    file_path = "config/initializers/hydra_config.rb"
    copy_file "config/initializers/hydra_config.rb", file_path
    insert_into_file file_path, :after => '# specify the user model' do
        "\n    config[:user_model] = '#{model_name.classify}'"
    end

    copy_file "config/initializers/action_dispatch_http_upload_monkey_patch.rb", "config/initializers/action_dispatch_http_upload_monkey_patch.rb"

    # Role Mappings
    copy_file "config/role_map_cucumber.yml", "config/role_map_cucumber.yml"
    copy_file "config/role_map_development.yml", "config/role_map_development.yml"
    copy_file "config/role_map_production.yml", "config/role_map_production.yml"
    copy_file "config/role_map_test.yml", "config/role_map_test.yml"

    # CanCan ability.rb
    copy_file "ability.rb", "app/models/ability.rb"

    # Fedora & Solr YAML files
    invoke('active_fedora:config')
  end

  # Add Hydra behaviors to the user model
  def inject_hydra_user_behavior
    file_path = "app/models/#{model_name.underscore}.rb"
    if File.exists?(file_path)
      inject_into_class file_path, model_name.classify do
        "# Connects this user object to Hydra behaviors. " +
        "\n include Hydra::User\n"
      end
    else
      puts "     \e[31mFailure\e[0m  Hydra requires a user object in order to apply access controls. This generators assumes that the model is defined in the file #{file_path}, which does not exist.  If you used a different name, please re-run the generator and provide that name as an argument. Such as \b  rails -g hydra:head client"
    end
  end

  # Inject call to HydraHead.add_routes in config/routes.rb
  def inject_hydra_routes
    insert_into_file "config/routes.rb", :after => 'Blacklight.add_routes(self)' do
      "\n  # Add Hydra routes.  For options, see API docs for HydraHead.routes"
      "\n  HydraHead.add_routes(self)"
    end
  end

end # HeadGenerator
end # Hydra
