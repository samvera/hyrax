# -*- encoding : utf-8 -*-
require 'rails/generators'
require 'rails/generators/migration'

class SufiaGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)

  argument     :model_name, :type => :string , :default => "user"
  desc """
This generator makes the following changes to your application:
 1. Runs sufia-models:install
 2. Adds controller behavior to the application controller
 3. Copies the catalog controller into the local app
       """

  def run_required_generators
    generate "blacklight --devise"
    generate "hydra:head -f"
    generate "sufia:models:install"
  end

  # Add behaviors to the application controller
  def inject_sufia_controller_behavior
    controller_name = "ApplicationController"
    file_path = "app/controllers/application_controller.rb"
    if File.exists?(file_path)
      insert_into_file file_path, :after => 'include Blacklight::Controller' do
        "  \n# Adds Sufia behaviors into the application controller \n" +
        "  include Sufia::Controller\n"
      end
      gsub_file file_path, "layout 'blacklight'", "layout :search_layout"
    else
      puts "     \e[31mFailure\e[0m  Could not find #{file_path}.  To add Sufia behaviors to your  Controllers, you must include the Sufia::Controller module in the Controller class definition."
    end
  end


  def catalog_controller
    copy_file "catalog_controller.rb", "app/controllers/catalog_controller.rb"
  end


  # The engine routes have to come after the devise routes so that /users/sign_in will work
  def inject_routes
    routing_code = "Hydra::BatchEdit.add_routes(self)"
    sentinel = /HydraHead.add_routes\(self\)/
    inject_into_file 'config/routes.rb', "\n  #{routing_code}\n", { :after => sentinel, :verbose => false }

    routing_code = "\n  # This must be the very last route in the file because it has a catch all route for 404 errors.
  # This behavior seems to show up only in production mode.
  mount Sufia::Engine => '/'\n"
    sentinel = /devise_for :users/
    inject_into_file 'config/routes.rb', routing_code, { :after => sentinel, :verbose => false }

  end

end


