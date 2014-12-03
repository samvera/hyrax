require_relative 'abstract_migration_generator'

class Sufia::Models::CachedStatsGenerator < Sufia::Models::AbstractMigrationGenerator
  source_root File.expand_path('../templates', __FILE__)
  argument :model_name, type: :string , default: "user"

  desc """
This generator adds the ability to cache usage stats to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
 2. Adds stats methods to the user model
       """

  def banner
    say_status("warning", "ADDING STATS CACHING-RELATED SUFIA MODELS", :yellow)
  end

  # Setup the database migrations
  def copy_migrations
    [
      'create_file_view_stats.rb',
      'create_file_download_stats.rb',
      'create_user_stats.rb'
    ].each do |file|
      better_migration_template file
    end
  end

  def add_stats_mixin_to_user_model
    file_path = "app/models/#{model_name.underscore}.rb"

    if File.exists?(file_path)
      inject_into_file file_path, after: /include Sufia\:\:User.*$/ do
        "\n include Sufia::UserUsageStats"
      end
    else
      puts "     \e[31mFailure\e[0m  Sufia requires a user object. This generators assumes that the model is defined in the file #{file_path}, which does not exist.  If you used a different name, please re-run the generator and provide that name as an argument. Such as \b  rails -g sufia client"
    end
  end
end
