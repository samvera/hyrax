namespace :hyhead do
    desc "Call repo:delete from within the test app"
    task :delete => :test_app_exists do
      within_test_app do
        puts %x[rake repo:delete]
      end
    end
    
    desc "Call repo:export from within the test app"
    task :export => :test_app_exists do
      within_test_app do
        puts %x[rake repo:export]
      end
    end
    
    desc "Call repo:load from within the test app"
    task :load => :test_app_exists do
      within_test_app do
        puts %x[rake repo:load]
      end
    end    
    
    desc "Call repo:refresh from within the test app"
    task :refresh => :test_app_exists do
      within_test_app do
        puts %x[rake repo:refresh]
      end
    end

    desc "Call repo:delete_range from within the test app"
    task :delete_range => :test_app_exists do
      within_test_app do
        puts %x[rake repo:delete_range]
      end
    end

  namespace :fixtures do
    
    desc "Call hydra:fixtures:refresh from within the test app"
    task :refresh => :test_app_exists do
      within_test_app do
        puts %x[rake hydra:fixtures:refresh]
      end
    end
    desc "Call hydra:fixtures:load from within the test app"
    task :load => :test_app_exists do
      within_test_app do
        puts %x[rake hydra:fixtures:load]
      end
    end
    desc "Call hydra:fixtures:delete from within the test app"
    task :delete => :test_app_exists do
      within_test_app do
        puts %x[rake hydra:fixtures:delete]
      end
    end
  end
end
