# -*- encoding : utf-8 -*-
require 'rails/generators'
require 'rails/generators/migration'     

class ScholarsphereGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)
  
  argument     :model_name, :type => :string , :default => "user"
  desc """
This generator makes the following changes to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
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

  def create_configuration_files
    copy_file "config/scholarsphere.rb", "config/initializers/scholarsphere.rb"
  end

  def catalog_controller
    copy_file "catalog_controller.rb", "app/controllers/catalog_controller.rb"
  end
  

  def inject_routes
    # These will end up in routes.rb file in reverse order
    # we add em, since each is added at the top of file. 
    # we want "root" to be FIRST for optimal url generation. 
    route "mount Scholarsphere::Engine => '/'"
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


