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

  namespace :fixture do
    desc "[DEPRECATED] Call hydra:delete"
    task :delete do
      STDERR.puts "DEPRECATED: hyhead:fixture:delete is deprecated.  Use/override hyhead:delete instead."
      Rake::Task["hyhead:delete"].invoke
    end
    
    desc "[DEPRECATED] Call hydra:harvest_fixture"
    task :harvest => ["hyhead:use_test_app"] do
      STDERR.puts "DEPRECATED: hyhead:fixture:harvest is deprecated.  Use/override hyhead:export instead."
      Rake::Task["hyhead:export"].invoke
    end
    
    desc "[DEPRECATED] Call hydra:import_fixture from within the test app"
    task :import => ["hyhead:use_test_app"] do
      STDERR.puts "DEPRECATED: hyhead:fixture:import is deprecated.  Use/override hyhead:load instead."
      Rake::Task["hyhead:load"].invoke
    end
    
    
    desc "[DEPRECATED] Call hydra:refresh_fixture from within the test app"
    task :refresh => ["hyhead:use_test_app"] do
      STDERR.puts "DEPRECATED: hyhead:fixture:refresh is deprecated.  Use/override hyhead:refresh instead."
      Rake::Task["hyhead:refresh"].invoke
    end
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
    
    
    desc "[DEPRECATED] Call hydra:purge_range"
    task :purge_range => ["hyhead:use_test_app"] do
      STDERR.puts "DEPRECATED: hyhead:fixtures:purge_range is deprecated.  Use/override hyhead:delete_range instead."
      Rake::Task["hyhead:delete_range"].invoke
    end
  end
end
