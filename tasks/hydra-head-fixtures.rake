require 'rspec/core'
require 'rspec/core/rake_task'
require "active-fedora"

namespace :hyhead do
    desc "Call repo:delete from within the test app"
    task :delete => ["hyhead:use_test_app"] do
      puts %x[rake repo:delete]
      FileUtils.cd('../../')
    end
    
    desc "Call repo:export from within the test app"
    task :export => ["hyhead:use_test_app"] do
      puts %x[rake repo:export]
      FileUtils.cd('../../')
    end
    
    desc "Call repo:load from within the test app"
    task :load => ["hyhead:use_test_app"] do
      puts %x[rake repo:load]
      FileUtils.cd('../../')
    end    
    
    desc "Call repo:refresh from within the test app"
    task :refresh => ["hyhead:use_test_app"] do
      puts %x[rake repo:refresh]
      FileUtils.cd('../../')
    end

    desc "Call repo:delete_range from within the test app"
    task :delete_range => ["hyhead:use_test_app"] do
      puts %x[rake repo:delete_range]
      FileUtils.cd('../../')
    end

  namespace :fixtures do
    
    desc "Call hydra:fixtures:refresh from within the test app"
    task :refresh => ["hyhead:use_test_app"] do
      puts %x[rake hydra:fixtures:refresh]
      FileUtils.cd('../../')
    end
    desc "Call hydra:fixtures:load from within the test app"
    task :load => ["hyhead:use_test_app"] do
      puts %x[rake hydra:fixtures:load]
      FileUtils.cd('../../')
    end
    desc "Call hydra:fixtures:delete from within the test app"
    task :delete => ["hyhead:use_test_app"] do
      puts %x[rake hydra:fixtures:delete]
      FileUtils.cd('../../')
    end
  end
end
