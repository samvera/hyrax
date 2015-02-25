require_relative 'abstract_migration_generator'

class Sufia::Models::UserStatsGenerator < Sufia::Models::AbstractMigrationGenerator
  source_root File.expand_path('../templates', __FILE__)
  argument :model_name, type: :string, default: "user"

  desc """
This generator adds usage stats methods to the user model in your application:
       """

  def banner
    say_status("info", "ADDING USER STATS-RELATED ABILITIES TO SUFIA MODELS", :blue)
  end

  # Setup the database migrations
  def copy_migrations
    better_migration_template 'create_user_stats.rb'
  end

  def add_stats_mixin_to_user_model
    file_path = "app/models/#{model_name.underscore}.rb"

    if File.exist?(file_path)
      inject_into_file file_path, after: /include Sufia\:\:User.*$/ do
        "\n  include Sufia::UserUsageStats"
      end
    else
      puts "     \e[31mFailure\e[0m  Sufia requires a user object. This generator assumes that the model is defined in the file #{file_path}, which does not exist.  If you used a different name, please re-run the generator and provide that name as an argument. Such as \b  rails g sufia:models:user_stats client"
    end
  end
end
