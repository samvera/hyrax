require 'rspec/core'
require 'rspec/core/rake_task'

namespace :hyhead do
  namespace :fixture do
    desc "Call hydra:delete"
    task :delete => ["hyhead:use_test_app"] do
      puts %x[rake hydra:delete]
      FileUtils.cd('../../')
    end
    
    desc "Call hydra:harvest_fixture"
    task :harvest => ["hyhead:use_test_app"] do
      puts %x[rake hydra:harvest_fixture]
      FileUtils.cd('../../')
    end
    
    desc "Call hydra:import_fixture from within the test app"
    task :import => ["hyhead:use_test_app"] do
      puts %x[rake hydra:import_fixture]
      FileUtils.cd('../../')
    end
    
    
    desc "Call hydra:refresh_fixture from within the test app"
    task :refresh => ["hyhead:use_test_app"] do
      puts %x[rake hydra:refresh_fixture]
      FileUtils.cd('../../')
    end
  end
  
  namespace :fixtures do
    
    desc "Call hydra:fixtures:refresh from within the test app"
    task :refresh => ["hyhead:use_test_app"] do
      puts %x[rake hydra:fixtures:refresh]
      FileUtils.cd('../../')
    end
    # task :load => ["hyhead:use_test_app"] do
    #   Rake::Task['hydra:default_fixtures:load'].invoke
    # end
    # task :delete do
    #   Rake::Task['hydra:default_fixtures:delete'].invoke
    # end
    
    
    desc "Call hydra:purge_range"
    task :purge_range => ["hyhead:use_test_app"] do
      puts %x[rake hydra:purge_range]
      FileUtils.cd('../../')
    end
  end
end
