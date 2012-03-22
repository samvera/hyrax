require 'rspec/core'
require 'rspec/core/rake_task'
#require 'thor/core_ext/file_binary_read'

namespace :gamma do

  desc "Execute Continuous Integration build (docs, tests with coverage)"
  task :ci do
    #Rake::Task["hyhead:doc"].invoke
    Rake::Task["jetty:config"].invoke
    Rake::Task["db:migrate"].invoke
    
    require 'jettywrapper'
    jetty_params = Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.dirname(__FILE__) + '/../jetty')})
    
    error = nil
    error = Jettywrapper.wrap(jetty_params) do
        Rake::Task['spec'].invoke
        Rake::Task['cucumber:ok'].invoke
    end
    raise "test failures: #{error}" if error
  end
end
