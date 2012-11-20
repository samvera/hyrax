# -*- encoding : utf-8 -*-
require 'rails/generators'
require 'rails/generators/migration'     

class SufiaGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)
  
  argument     :model_name, :type => :string , :default => "user"
  desc """
This generator makes the following changes to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
 2. Adds user behavior to the user model
 3. Adds controller behavior to the application controller
 4. Creates the sufia.rb configuration file
 5. Copies the catalog controller into the local app
 6. Generates mailboxer
       """ 

  # Implement the required interface for Rails::Generators::Migration.
  # taken from http://github.com/rails/rails/blob/master/activerecord/lib/generators/active_record.rb
  def self.next_migration_number(path)
    unless @prev_migration_nr
      @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
    else
      @prev_migration_nr += 1
    end
    @prev_migration_nr.to_s
  end

  # Setup the database migrations
  def copy_migrations
    # Can't get this any more DRY, because we need this order.
    %w{acts_as_follower_migration.rb	add_social_to_users.rb		create_single_use_links.rb
add_avatars_to_users.rb		create_checksum_audit_logs.rb	create_version_committers.rb
add_groups_to_users.rb		create_local_authorities.rb}.each do |f|
      better_migration_template f
    end
  end

  # Add behaviors to the user model
  def inject_sufia_user_behavior
    file_path = "app/models/#{model_name.underscore}.rb"
    if File.exists?(file_path) 
      inject_into_class file_path, model_name.classify do 
        "# Connects this user object to Sufia behaviors. " +
        "\n include Sufia::User\n"        
      end
    else
      puts "     \e[31mFailure\e[0m  Sufia requires a user object. This generators assumes that the model is defined in the file #{file_path}, which does not exist.  If you used a different name, please re-run the generator and provide that name as an argument. Such as \b  rails -g sufia client" 
    end    
  end

  # Add behaviors to the application controller
  def inject_sufia_controller_behavior    
    controller_name = "ApplicationController"
    file_path = "app/controllers/application_controller.rb"
    if File.exists?(file_path) 
      insert_into_file file_path, :after => 'include Hydra::Controller::ControllerBehavior' do 
        "  \n# Adds Sufia behaviors into the application controller \n" +        
        "  include Sufia::Controller\n"
      end
    else
      puts "     \e[31mFailure\e[0m  Could not find #{file_path}.  To add Sufia behaviors to your  Controllers, you must include the Sufia::Controller module in the Controller class definition." 
    end
  end
  
  def create_configuration_files
    copy_file "config/sufia.rb", "config/initializers/sufia.rb"
    copy_file "config/redis_config.rb", "config/initializers/redis_config.rb"
  end

  def catalog_controller
    copy_file "catalog_controller.rb", "app/controllers/catalog_controller.rb"
  end
  

  # The engine routes have to come after the devise routes so that /users/sign_in will work
  def inject_routes
    routing_code = "mount Sufia::Engine => '/'"
    sentinel = /devise_for :users/
    inject_into_file 'config/routes.rb', "\n  #{routing_code}\n", { :after => sentinel, :verbose => false }
    
  end

  def install_mailboxer
    generate "mailboxer:install" 
  end

  private  
  
  def better_migration_template (file)
    begin
      migration_template "migrations/#{file}", "db/migrate/#{file}"
      sleep 1 # ensure scripts have different time stamps
    rescue
      puts "  \e[1m\e[34mMigrations\e[0m  " + $!.message
    end
  end

end  


