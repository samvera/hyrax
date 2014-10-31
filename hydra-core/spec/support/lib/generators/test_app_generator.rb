require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../support", __FILE__)

  def copy_test_classes
    # Download controller
    copy_file "app/controllers/downloads_controller.rb"
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
