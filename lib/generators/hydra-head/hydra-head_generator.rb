# -*- encoding : utf-8 -*-
require 'rails/generators'
require 'rails/generators/migration'     

require "generators/blacklight/blacklight_generator"

class HydraHeadGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  
  source_root File.expand_path('../templates', __FILE__)
  
    desc """
  This generator makes the following changes to your application:
   1. ...
   2. ...
  Enjoy building your Hydra Head!
         """
  
  # Copy all files in templates/config directory to host config
  def create_configuration_files
    # Initializers
   copy_file "config/initializers/fedora_config.rb", "config/initializers/fedora_config.rb"
   copy_file "config/initializers/hydra_config.rb", "config/initializers/hydra_config.rb"

   # Role Mappings
   copy_file "config/role_map_cucumber.yml", "config/role_map_cucumber.yml"
   copy_file "config/role_map_development.yml", "config/role_map_development.yml"
   copy_file "config/role_map_production.yml", "config/role_map_production.yml"
   copy_file "config/role_map_test.yml", "config/role_map_test.yml"
   
   # Solr Mappings
   copy_file "config/solr_mappings.yml", "config/solr_mappings.yml"

   # Fedora & Solr YAML files
   copy_file "config/fedora.yml", "config/fedora.yml"
   copy_file "config/solr.yml", "config/solr.yml"
  end
         
  # wraps BlacklightGenerator.better_migration_template        
  def self.better_migration_template(file)
    BlacklightGenerator.better_migration_template(file)
  end
end