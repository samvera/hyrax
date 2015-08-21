require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root '../../spec/test_app_templates'

  def install_engine
    generate 'curation_concerns:install'
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
end
