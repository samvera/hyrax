require_relative 'abstract_migration_generator'

class Sufia::Models::Upgrade400Generator < Sufia::Models::AbstractMigrationGenerator
  source_root File.expand_path('../templates', __FILE__)

  desc """
This generator for upgrading sufia-models from 3.7.2 to 4.0 makes the following changes to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
 2. Runs the mailboxer upgrade generator
 3. Adds analytics to the sufia.rb configuration file
 4. Runs full-text generator
       """

  def banner
    say_status("info", "UPGRADING SUFIA MODELS", :blue)
  end

  # Setup the database migrations
  def copy_migrations
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
end
