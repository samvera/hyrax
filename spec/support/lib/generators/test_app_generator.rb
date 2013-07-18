require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../support", __FILE__)

  def run_blacklight_generator
    say_status("warning", "GENERATING BL", :yellow)       

    generate 'blacklight', '--devise'
  end

  def run_hydra_head_generator
    say_status("warning", "GENERATING HH", :yellow)       

    generate 'hydra:head', '-f'
  end

  def run_sufia_generator
    say_status("warning", "GENERATING SUFIA", :yellow)       

    generate 'sufia', '-f'

    remove_file 'spec/factories/users.rb'
  end

  def remove_index_page
    remove_file 'public/index.html'
  end

  def copy_rspec_rake_task
    copy_file "lib/tasks/rspec.rake"
  end
  
end
