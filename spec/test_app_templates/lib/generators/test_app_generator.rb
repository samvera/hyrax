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

  def copy_fixture_data
    generate 'curation_concerns:sample_data', '-f'
  end

  def enable_i18n_translation_errors
    gsub_file "config/environments/development.rb",
              "# config.action_view.raise_on_missing_translations = true", "config.action_view.raise_on_missing_translations = true"
    gsub_file "config/environments/test.rb",
              "# config.action_view.raise_on_missing_translations = true", "config.action_view.raise_on_missing_translations = true"
  end
end
