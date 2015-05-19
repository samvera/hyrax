require_relative 'abstract_migration_generator'

class Sufia::Models::Upgrade600Generator < Sufia::Models::AbstractMigrationGenerator
  source_root File.expand_path('../templates', __FILE__)

  desc """
This generator for upgrading sufia-models to 6.0 makes the following changes to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
       """

  # Setup the database migrations
  def copy_migrations
    [
      'change_audit_log_pid_to_generic_file_id.rb',
      'change_proxy_deposit_request_pid_to_generic_file_id.rb'
    ].each do |file|
      better_migration_template file
    end
  end
end

