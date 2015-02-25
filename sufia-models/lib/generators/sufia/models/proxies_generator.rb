require_relative 'abstract_migration_generator'

class Sufia::Models::ProxiesGenerator < Sufia::Models::AbstractMigrationGenerator
  source_root File.expand_path('../templates', __FILE__)

  desc """
This generator adds proxies and transfers to your application:
 1. Creates several database migrations if they do not exist in /db/migrate
       """

  def banner
    say_status("info", "ADDING PROXY/TRANSFER-RELATED SUFIA MODELS", :blue)
  end

  # Setup the database migrations
  def copy_migrations
    [
      'create_proxy_deposit_rights.rb',
      'create_proxy_deposit_requests.rb'
    ].each do |file|
      better_migration_template file
    end
  end
end
