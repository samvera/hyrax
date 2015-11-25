require_relative 'abstract_migration_generator'

class Sufia::Models::CachedStatsGenerator < Sufia::Models::AbstractMigrationGenerator
  source_root File.expand_path('../templates', __FILE__)

  desc """
This generator adds the ability to cache usage stats to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
       """

  def banner
    say_status("info", "ADDING STATS CACHING-RELATED SUFIA MODELS", :blue)
  end

  # Setup the database migrations
  def copy_migrations
    [
      'create_file_view_stats.rb',
      'create_file_download_stats.rb'
    ].each do |file|
      better_migration_template file
    end
  end
end
