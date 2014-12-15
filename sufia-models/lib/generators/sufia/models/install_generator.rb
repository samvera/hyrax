require_relative 'abstract_migration_generator'

class Sufia::Models::InstallGenerator < Sufia::Models::AbstractMigrationGenerator
  source_root File.expand_path('../templates', __FILE__)
  argument     :model_name, type: :string , default: "user"
  desc """
This generator makes the following changes to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
 2. Adds user behavior to the user model
 3. Creates the sufia.rb configuration file
 4. Generates mailboxer
 5. Generates usage stats config
 6. Installs Blacklight gallery
 7. Runs full-text generator
 8. Runs proxies generator
 9. Runs cached stats generator
10. Runs ORCID field generator
11. Runs user stats generator
       """
  def banner
    say_status("warning", "GENERATING SUFIA MODELS", :yellow)
  end

  # Setup the database migrations
  def copy_migrations
    [
      "acts_as_follower_migration.rb",
      "add_social_to_users.rb",
      "create_single_use_links.rb",
      "add_ldap_attrs_to_user.rb",
      "add_avatars_to_users.rb",
      "create_checksum_audit_logs.rb",
      "create_version_committers.rb",
      "add_groups_to_users.rb",
      "create_local_authorities.rb",
      "create_trophies.rb",
      'add_linkedin_to_users.rb',
      'create_tinymce_assets.rb',
      'create_content_blocks.rb',
      'create_featured_works.rb'
    ].each do |file|
      better_migration_template file
    end
  end

  # Add behaviors to the user model
  def inject_sufia_user_behavior
    file_path = "app/models/#{model_name.underscore}.rb"
    if File.exists?(file_path)
      inject_into_file file_path, after: /include Hydra\:\:User.*$/ do
        "# Connects this user object to Sufia behaviors. " +
          "\n include Sufia::User\n"
      end
    else
      puts "     \e[31mFailure\e[0m  Sufia requires a user object. This generators assumes that the model is defined in the file #{file_path}, which does not exist.  If you used a different name, please re-run the generator and provide that name as an argument. Such as \b  rails -g sufia client"
    end
  end

  def create_configuration_files
    append_file 'config/initializers/mime_types.rb',
                     "\nMime::Type.register 'application/x-endnote-refer', :endnote", {verbose: false }
    copy_file 'config/sufia.rb', 'config/initializers/sufia.rb'
    copy_file 'config/redis.yml', 'config/redis.yml'
    copy_file 'config/resque-pool.yml', 'config/resque-pool.yml'
    copy_file 'config/redis_config.rb', 'config/initializers/redis_config.rb'
    copy_file 'config/resque_admin.rb', 'config/initializers/resque_admin.rb'
    copy_file 'config/resque_config.rb', 'config/initializers/resque_config.rb'
  end

  def install_mailboxer
    generate "mailboxer:install"
  end

  def configure_usage_stats
    generate 'sufia:models:usagestats'
  end

  def install_blacklight_gallery
    generate "blacklight_gallery:install"
  end

  # Sets up full-text indexing (Solr config + jars)
  def full_text_indexing
    generate "sufia:models:fulltext"
  end

  # Sets up proxies and transfers
  def proxies
    generate "sufia:models:proxies"
  end

  # Sets up cached usage stats
  def cached_stats
    generate 'sufia:models:cached_stats'
  end

  # Adds orcid field to user model
  def orcid_field
    generate 'sufia:models:orcid_field'
  end

  # Adds user stats-related migration & methods
  def user_stats
    generate 'sufia:models:user_stats'
  end
end
