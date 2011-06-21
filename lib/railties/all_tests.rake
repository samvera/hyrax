namespace :hyhead do
  begin
    require 'cucumber/rake/task'
    require 'rspec/core'
    require 'rspec/core/rake_task'

    desc "Run HydraHead cucumber and rspec, with test solr"
    task :all_tests => ['hyhead:spec:with_solr', 'hyhead:cucumber:with_solr']
    
    namespace :all_tests do
      desc "Run HydraHead rspec and cucumber tests with rcov"
      rm "hyhead-coverage.data" if File.exist?("hyhead-coverage.data")
      task :rcov => ['hyhead:spec:rcov', 'hyhead:cucumber:rcov']
    end
    
  rescue LoadError
    desc "Not available! (cucumber and rspec not avail)"
    task :all_tests do
      abort 'Not available. Both cucumber and rspec need to be installed to run hyhead:all_tests'
    end
  end
end

