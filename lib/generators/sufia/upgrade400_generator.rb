require_relative 'abstract_migration_generator'

class Sufia::Upgrade400Generator < Sufia::AbstractMigrationGenerator
  source_root File.expand_path('../templates', __FILE__)

  argument :model_name, type: :string, default: "user"
  desc """
This generator for upgrading sufia from 3.7.2 to 4.0 makes the following changes to your application:
 1. Updates the root route
 2. Adds Sufia's abilities into the Ability class
 3. Adds Sufia behavior to the catalog controller
 4. Creates a Sufia helper
 5. Removes Blacklight stylesheet
 6. Creates TinyMCE config for editable content feature
 7. Adds blacklight-marc dependency if SolrDocument depends on it
 8. Runs model-related concerns
   * Creates several database migrations if they do not exist in /db/migrate
   * Runs the mailboxer upgrade generator
   * Adds analytics to the sufia.rb configuration file
   * Runs full-text generator

       """

  def banner
    say_status("info", "UPGRADING SUFIA", :blue)
  end

  # The engine routes have to come after the devise routes so that /users/sign_in will work
  def update_root_route
    # Nuke old Sufia-related routes
    gsub_file 'config/routes.rb', 'root :to => "catalog#index"', "root to: 'homepage#index'"
  end

  def insert_abilities
    insert_into_file 'app/models/ability.rb', after: /Hydra::Ability/ do
      "\n  include Sufia::Ability\n"
    end
  end

  # Add Sufia behaviors to the catalog controller
  def inject_sufia_controller_behavior
    file_path = "app/controllers/catalog_controller.rb"
    if File.exist?(file_path)
      insert_into_file file_path, after: 'include Hydra::Controller::ControllerBehavior' do
        "\n  # Adds Sufia behaviors to the catalog controller\n" \
        "  include Sufia::Catalog\n"
      end
    else
      puts "     \e[31mFailure\e[0m  Could not find #{file_path}.  To add Sufia behaviors to your Controllers, you must include the Sufia::Catalog module in the CatalogController class definition."
    end
  end

  def copy_helper
    copy_file 'sufia_helper.rb', 'app/helpers/sufia_helper.rb'
  end

  def remove_blacklight_scss
    remove_file 'app/assets/stylesheets/blacklight.css.scss'
  end

  def install_blacklight_gallery
    generate "blacklight_gallery:install"
  end

  def tinymce_config
    copy_file "config/tinymce.yml", "config/tinymce.yml"
  end

  def blacklight_marc
    file_path = 'app/models/solr_document.rb'
    return unless File.exist?(file_path) &&
                  file_contains?('app/models/solr_document.rb', 'Blacklight::Solr::Document::Marc') &&
                  !file_contains?('Gemfile', 'blacklight-marc')
    insert_into_file 'Gemfile', after: /gem 'sufia'.*$/ do
      "\ngem 'blacklight-marc'"
    end
    Bundler.with_clean_env do
      run 'bundle install'
    end
  end

  # Setup the database migrations
  def copy_migrations
    [
      'create_tinymce_assets.rb',
      'create_content_blocks.rb',
      'create_featured_works.rb'
    ].each do |file|
      better_migration_template file
    end
  end

  # Upgrade mailboxer
  def install_mailboxer
    generate "mailboxer:namespacing_compatibility"
    generate "mailboxer:install -s"
  end

  # Add config file for Google Analytics
  def add_analytics_config
    copy_file 'config/analytics.yml', 'config/analytics.yml'
  end

  # Add Google Analytics option to Sufia config
  def inject_analytics_initializer
    inject_into_file 'config/initializers/sufia.rb', after: /^Sufia\.config do.*$/ do
      "\n  # Enable displaying usage statistics in the UI\n" \
        "  # Defaults to FALSE\n" \
        "  # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info\n" \
        "  #config.analytics = false\n"
    end
  end

  # Sets up full-text indexing (Solr config + jars)
  def full_text_indexing
    generate "sufia:fulltext"
  end

  private

    def file_contains?(path, string)
      File.readlines(path).grep(/#{string}/).any?
    end
end
