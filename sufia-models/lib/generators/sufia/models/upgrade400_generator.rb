# -*- encoding : utf-8 -*-
require 'rails/generators'
require 'rails/generators/migration'

class Sufia::Models::Upgrade400Generator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)

  argument     :model_name, type: :string , default: "user"
  desc """
This generator for upgrading sufia-models from 3.7.2 to 4.0 makes the following changes to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
 2. Runs the mailboxer upgrade generator
 3. Adds analytics to the sufia.rb configuration file
 4. Runs full-text generator
       """

  # Implement the required interface for Rails::Generators::Migration.
  # taken from http://github.com/rails/rails/blob/master/activerecord/lib/generators/active_record.rb
  def self.next_migration_number(path)
    if @prev_migration_nr
      @prev_migration_nr += 1
    else
      if last_migration = Dir[File.join(path, '*.rb')].sort.last
        @prev_migration_nr = last_migration.sub(File.join(path, '/'), '').to_i + 1
      else
        @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
      end
    end
    @prev_migration_nr.to_s
  end

  def banner
    say_status("warning", "UPGRADING SUFIA MODELS", :yellow)
  end

  # Setup the database migrations
  def copy_migrations
    # Can't get this any more DRY, because we need this order.
    [
      'create_tinymce_assets.rb',
      'create_content_blocks.rb',
      'create_featured_works.rb'
    ].each do |file|
      better_migration_template file
    end
  end

  # Upgrade mailboxer
  def install_mailboxer
    generate "mailboxer:namespacing_compatibility"
    generate "mailboxer:install -s"
  end

  # Add config file for Google Analytics
  def add_analytics_config
    copy_file 'config/analytics.yml', 'config/analytics.yml'
  end

  # Add Google Analytics option to Sufia config
  def inject_analytics_initializer
    inject_into_file 'config/initializers/sufia.rb', after: /^Sufia\.config do.*$/ do
      "\n  # Enable displaying usage statistics in the UI\n" +
        "  # Defaults to FALSE\n" +
        "  # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info\n" +
        "  #config.analytics = false\n"
      end
  end

  # Sets up full-text indexing (Solr config + jars)
  def full_text_indexing
    generate "sufia:models:fulltext"
  end

  private

  def better_migration_template(file)
    begin
      migration_template "migrations/#{file}", "db/migrate/#{file}"
    rescue Rails::Generators::Error => e
      say_status("warning", e.message, :yellow)
    end
  end
end
