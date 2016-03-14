require_relative 'abstract_migration_generator'

class Sufia::CachedWorkStatsGenerator < Sufia::AbstractMigrationGenerator
  source_root File.expand_path('../templates', __FILE__)

  desc """
This generator adds the ability to cache usage stats to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
       """

  def banner
    say_status("info", "ADDING WORK STATS CACHING-RELATED TABLES", :blue)
  end

  # Setup the database migrations
  def copy_migrations
    [
      'create_work_view_stats.rb',
      'add_works_to_user_stats.rb'
    ].each do |file|
      better_migration_template file
    end
  end
end
