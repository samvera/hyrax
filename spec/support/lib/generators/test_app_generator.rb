require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../support", __FILE__)

  def run_sufia_generator
    say_status("warning", "GENERATING SUFIA", :yellow)
    generate 'sufia', '-f'
    remove_file 'spec/factories/users.rb'
  end

  def add_create_permissions
    insert_into_file 'app/models/ability.rb', after: 'custom_permissions' do
      "\n    can :create, :all if user_groups.include? 'registered'\n"
    end
  end
end
