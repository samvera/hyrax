require_relative 'abstract_migration_generator'

class Sufia::Models::InstallGenerator < Sufia::Models::AbstractMigrationGenerator
  source_root File.expand_path('../templates', __FILE__)
  argument :model_name, type: :string, default: "user", desc: "Model name for User model (primarily passed to devise, but also used elsewhere)"
  class_option :skip_curation_concerns, type: :boolean, default: false, desc: "whether to skip the curation_concerns:models installer"
  desc """
This generator makes the following changes to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
 2. Adds user behavior to the user model
 3. Generates GenericWork model.
 4. Creates the sufia.rb configuration file
 5. Generates mailboxer
 6. Generates usage stats config
 7. Runs full-text generator
 8. Runs proxies generator
 9. Runs cached stats generator
10. Runs ORCID field generator
11. Runs user stats generator
       """

  def banner
    say_status("warning", "GENERATING SUFIA MODELS", :yellow)
  end

  def run_curation_concerns_models_installer
    generate 'curation_concerns:models:install' unless options[:skip_curation_concerns]
  end

  def run_curation_concerns_work_generator
    generate 'curation_concerns:work GenericWork'
  end

  # Setup the database migrations
  def copy_migrations
    [
      "acts_as_follower_migration.rb",
      "add_social_to_users.rb",
      "create_single_use_links.rb",
      "add_ldap_attrs_to_user.rb",
      "add_avatars_to_users.rb",
      "add_groups_to_users.rb",
      "create_local_authorities.rb",
      "create_trophies.rb",
      'add_linkedin_to_users.rb',
      'create_tinymce_assets.rb',
      'create_content_blocks.rb',
      'create_featured_works.rb',
      'add_external_key_to_content_blocks.rb'
    ].each do |file|
      better_migration_template file
    end
  end

  def create_config_file
    copy_file 'config/sufia.rb', 'config/initializers/sufia.rb'
  end

  # Add behaviors to the user model
  def inject_sufia_user_behavior
    file_path = "app/models/#{model_name.underscore}.rb"
    if File.exist?(file_path)
      inject_into_file file_path, after: /include CurationConcerns\:\:User.*$/ do
        "\n  # Connects this user object to Sufia behaviors." +
          "\n  include Sufia::User\n"
      end
    else
      puts "     \e[31mFailure\e[0m  Sufia requires a user object. This generators assumes that the model is defined in the file #{file_path}, which does not exist.  If you used a different name, please re-run the generator and provide that name as an argument. Such as \b  rails -g sufia client"
    end
  end

  def inject_sufia_collection_behavior
    insert_into_file 'app/models/collection.rb', after: 'include ::CurationConcerns::CollectionBehavior' do
      "\n  include Sufia::CollectionBehavior"
    end
  end

  def inject_sufia_generic_work_behavior
    insert_into_file 'app/models/generic_work.rb', after: 'include ::CurationConcerns::GenericWorkBehavior' do
      "\n  include ::Sufia::GenericWorkBehavior"
    end
  end

  def inject_sufia_file_set_behavior
    insert_into_file 'app/models/file_set.rb', after: 'include ::CurationConcerns::FileSetBehavior' do
      "\n  include ::Sufia::FileSetBehavior"
    end
  end

  def install_mailboxer
    generate "mailboxer:install"
  end

  def configure_usage_stats
    generate 'sufia:models:usagestats'
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
