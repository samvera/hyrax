require_relative 'abstract_migration_generator'

class Sufia::Upgrade700Generator < Sufia::AbstractMigrationGenerator
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
    gsub_file 'app/controllers/catalog_controller.rb', '[:add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr]', '[:add_advanced_parse_q_to_solr] + search_params_logic + [:add_access_controls_to_solr_params]'
  end

  # Setup the database migrations
  def copy_migrations
    [
      'change_trophy_generic_file_id_to_work_id.rb',
      'change_proxy_deposit_generic_file_id_to_work_id.rb',
      'change_audit_log_generic_file_id_to_file_set_id.rb',
      'change_proxy_deposit_request_generic_file_id_to_work_id.rb',
      'change_featured_work_generic_file_id_to_work_id.rb'
    ].each do |file|
      better_migration_template file
    end
  end

  def inject_sufia_work_controller_behavior
    file_path = "app/controllers/curation_concerns/generic_works_controller.rb"
    if File.exist?(file_path)
      inject_into_file file_path, after: /include CurationConcerns::CurationConcernController/ do
        "\n  # Adds Sufia behaviors to the controller.\n" \
          "  include Sufia::WorksControllerBehavior\n"
      end
    else
      puts "     \e[31mFailure\e[0m  Sufia requires a CurationConcerns::GenericWorksController object. This generator assumes that the model is defined in the file #{file_path}, which does not exist."
    end
  end

  def install_assets
    generate "sufia:assets"
  end

  def install_batch_edit
    generate "hydra_batch_edit:install"
  end
end
