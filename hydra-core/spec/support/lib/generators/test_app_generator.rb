require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../support", __FILE__)

  def copy_test_fixtures
    copy_file "app/models/generic_content.rb"

    # Download controller
    copy_file "app/controllers/downloads_controller.rb"

    copy_file "spec/fixtures/hydrangea_fixture_mods_article1.foxml.xml" 

    # For testing Hydra::SubmissionWorkflow
    copy_file "spec/fixtures/hydra_test_generic_content.foxml.xml"
  end

  def copy_rspec_rake_task
    copy_file "lib/tasks/rspec.rake"
  end

  def run_blacklight_generator
    say_status("warning", "GENERATING BL", :yellow)       

    generate 'blacklight:install', '--devise'
  end

  def run_hydra_head_generator
    say_status("warning", "GENERATING HH", :yellow)       

    generate 'hydra:head', '-f --skip-rspec'
  end

  def remove_generated_user_spec
    remove_file 'spec/models/user_spec.rb'
  end
end
