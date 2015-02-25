require_relative 'abstract_migration_generator'

class Sufia::Models::OrcidFieldGenerator < Sufia::Models::AbstractMigrationGenerator
  source_root File.expand_path('../templates', __FILE__)

  desc """
This generator adds a field to hold users' ORCIDs to your application:
 1. Creates a database migration if they do not exist in /db/migrate
       """

  def banner
    say_status("info", "ADDING ORCID FIELD TO USER MODEL", :blue)
  end

  # Setup the database migration
  def copy_migrations
    better_migration_template 'add_orcid_to_users.rb'
  end
end
