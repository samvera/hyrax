require 'engine_cart'
require 'jasmine'
def jasmine_path
  Gem.loaded_specs['jasmine'].full_gem_path
end
import "#{jasmine_path}/lib/jasmine/tasks/jasmine.rake"
namespace :curation_concerns do
  task :jasmine do
    EngineCart.load_application!
    Rake::Task["jasmine"].invoke
  end
  namespace :jasmine do
    task :ci do
      EngineCart.load_application!
      Rake::Task["jasmine:ci"].invoke
    end
  end
end
