require_relative 'abstract_migration_generator'

class Sufia::Models::UpdateContentBlocksGenerator < Sufia::Models::AbstractMigrationGenerator
  source_root File.expand_path('../templates', __FILE__)

  desc """
This generator creates a database migration to add an external_key column to the content_blocks table (if the migration doesn't already exist).  This allows you to associate a user_key with a featured_researcher entry.
       """

  def banner
    say_status("info", "CREATING MIGRATION FILE", :blue)
  end

  def copy_migrations
    better_migration_template 'add_external_key_to_content_blocks.rb'
  end
end
