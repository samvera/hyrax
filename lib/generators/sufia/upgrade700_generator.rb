class Sufia::Upgrade700Generator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  argument :model_name, type: :string, default: "user"
  desc """
This generator for upgrading sufia from 6.0.0 to 7.0 makes the following changes to your application:
 1. Updates the Catalog Controller
 2. Creates several database migrations if they do not exist in /db/migrate

       """

  def banner
    say_status("info", "APPLYING SUFIA 7.0 CHANGES", :blue)
  end

  # The engine routes have to come after the devise routes so that /users/sign_in will work
  def update_catalog_controller
    # Nuke old search_params_logic
    gsub_file 'app/controllers/catalog_controller.rb', '[:add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr]', 'search_params_logic + [:add_access_controls_to_solr_params]'
  end

  def qa_routes
    insert_into_file "config/routes.rb", after: ".draw do" do
      "\n  mount Qa::Engine => '/authorities'\n"
    end
  end

  def qa_tables
    generate 'qa:local:tables'
  end
end
