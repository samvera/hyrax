require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../spec/test_app_templates", __FILE__)

  def install_engine
    generate 'curation_concerns:install', '-f'
  end

  def run_migrations
    rake 'db:migrate'
  end

  def generate_generic_work
    generate 'curation_concerns:work GenericWork'
  end

  def remove_generic_work_specs
    remove_file 'spec/models/generic_work_spec.rb'
    remove_file 'spec/controllers/curation_concerns/generic_works_controller_spec.rb'
    remove_file 'spec/actors/curation_concerns/generic_work_actor_spec.rb'
  end

  def copy_test_controller
    copy_file "app/controllers/other_collections_controller.rb"
    insert_into_file "config/routes.rb", after: '.draw do' do
      "\n  resources :other_collections, except: :index"
    end
  end
end
