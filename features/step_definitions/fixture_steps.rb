require "rake"

  def activefedora_path
    Gem.loaded_specs['active-fedora'].full_gem_path
  end

Given /^I load scholarsphere fixtures$/ do
    @rake = Rake::Application.new 
    Rake.application = @rake
    Rake.application.rake_require "lib/tasks/scholarsphere-fixtures", ["."]
    Rake.application.rake_require "lib/tasks/active_fedora", [activefedora_path]      
    Rake::Task.define_task(:environment)
    @rake['scholarsphere:fixtures:refresh'].invoke
end

