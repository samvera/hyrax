require "rake"

def loaded_files_excluding_current_rake_file
  $".reject { |file| file.include? "lib/tasks/scholarsphere-fixtures" }
end

def activefedora_path
  Gem.loaded_specs['active-fedora'].full_gem_path
end

Given /^I load scholarsphere fixtures$/ do
  @rake = Rake::Application.new
  Rake.application = @rake
  Rake.application.rake_require("lib/tasks/scholarsphere-fixtures", ["."], loaded_files_excluding_current_rake_file)
  Rake.application.rake_require("lib/tasks/active_fedora", [activefedora_path], loaded_files_excluding_current_rake_file)
  Rake::Task.define_task(:environment)
  @rake['scholarsphere:fixtures:refresh'].invoke
  @rake['scholarsphere:fixtures:fix'].invoke
end

