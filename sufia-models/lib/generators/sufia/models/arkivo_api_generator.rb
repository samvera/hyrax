require_relative 'abstract_migration_generator'

class Sufia::Models::ArkivoApiGenerator < Sufia::Models::AbstractMigrationGenerator
  source_root File.expand_path('../templates', __FILE__)

  desc """
This generator sets up Zotero/Arkivo API integration for your application:
       """

  def banner
    say_status("info", "ADDING ZOTERO/ARKIVO API INTEGRATION", :blue)
  end

  # Turn on the feature set in Sufia's config
  def inject_arkivo_config
    inject_into_file 'config/initializers/sufia.rb', after: /^Sufia\.config do.*$/ do
      "\n  # Sufia can integrate with Zotero's Arkivo service for automatic deposit\n" +
        "  # of Zotero-managed research items.\n" +
        "  # Defaults to false.  See README for more info\n" +
        "  config.arkivo_api = true\n"
    end
  end

  # Copy the routing constraint over
  def copy_routing_constraint
    copy_file 'config/arkivo_constraint.rb', 'config/initializers/arkivo_constraint.rb'
  end

  # Copy the database migration
  def copy_migration
    better_migration_template 'add_arkivo_to_users.rb'
  end

  # Copy the config files for Zotero and Arkivo
  def copy_config_files
    copy_file 'config/arkivo.yml', 'config/arkivo.yml'
    copy_file 'config/zotero.yml', 'config/zotero.yml'
  end
end
