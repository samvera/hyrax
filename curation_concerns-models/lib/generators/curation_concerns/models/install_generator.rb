require_relative 'abstract_migration_generator'

class CurationConcerns::Models::InstallGenerator < CurationConcerns::Models::AbstractMigrationGenerator
  source_root File.expand_path('../templates', __FILE__)
  argument :model_name, type: :string, default: 'user'
  desc ''"
This generator makes the following changes to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
 2. Creates the curation_concerns.rb configuration file and several others
 3. Creates the generic_file.rb, generic_work.rb and collection.rb models
 4. Runs full-text generator
       "''
  def banner
    say_status('warning', 'GENERATING CURATION_CONCERNS MODELS', :yellow)
  end

  # Setup the database migrations
  def copy_migrations
    [
      'create_version_committers.rb',
      'create_checksum_audit_logs.rb' # ,
    ].each do |file|
      better_migration_template file
    end
  end

  # Add behaviors to the user model
  def inject_curation_concerns_user_behavior
    file_path = "app/models/#{model_name.underscore}.rb"
    if File.exist?(file_path)
      inject_into_file file_path, after: /include Hydra\:\:User.*$/ do
        "\n  # Connects this user object to Curation Concerns behaviors." \
        "\n  include CurationConcerns::User\n"
      end
    else
      puts "     \e[31mFailure\e[0m  CurationConcerns requires a user object. This generators assumes that the model is defined in the file #{file_path}, which does not exist.  If you used a different name, please re-run the generator and provide that name as an argument. Such as \b  rails -g curation_concerns client"
    end
  end

  def create_configuration_files
    append_file 'config/initializers/mime_types.rb',
                "\nMime::Type.register 'application/x-endnote-refer', :endnote", verbose: false
    copy_file 'config/curation_concerns.rb', 'config/initializers/curation_concerns.rb'
    copy_file 'config/redis.yml', 'config/redis.yml'
    copy_file 'config/resque-pool.yml', 'config/resque-pool.yml'
    copy_file 'config/redis_config.rb', 'config/initializers/redis_config.rb'
    copy_file 'config/resque_admin.rb', 'config/initializers/resque_admin.rb'
    copy_file 'config/resque_config.rb', 'config/initializers/resque_config.rb'
  end

  def create_collection
    copy_file 'app/models/collection.rb', 'app/models/collection.rb'
  end

  def create_generic_file
    copy_file 'app/models/generic_file.rb', 'app/models/generic_file.rb'
  end

  # Sets up full-text indexing (Solr config + jars)
  def full_text_indexing
    generate 'curation_concerns:models:fulltext'
  end

  # Adds clamav initializtion
  def clamav
    generate 'curation_concerns:models:clamav'
  end
end
