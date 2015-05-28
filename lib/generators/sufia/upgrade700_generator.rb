# -*- encoding : utf-8 -*-
require 'rails/generators'
class Sufia::Upgrade700Generator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)

  argument :model_name, type: :string , default: "user"
  desc """
This generator for upgrading sufia from 6.0.0 to 7.0 makes the following changes to your application:
 1. Updates the Catalog Controller
 8. Runs sufia-models upgrade generator
       """

  def banner
    say_status("warning", "UPGRADING SUFIA", :yellow)
  end

  # The engine routes have to come after the devise routes so that /users/sign_in will work
  def update_catalog_controller
    # Nuke old search_params_logic
    gsub_file 'app/controllers/catalog_controller.rb', '[:add_access_controls_to_solr_params, :add_advanced_parse_q_to_solr]', '[:add_advanced_parse_q_to_solr] + search_params_logic + [:add_access_controls_to_solr_params]'
  end


  def upgrade_sufia_models
    generate "sufia:models:upgrade700"
  end

end
