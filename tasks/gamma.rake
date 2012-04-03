require 'rspec/core'
require 'rspec/core/rake_task'

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

  namespace :harvest do
    desc "Harvest and map LCSH"
    task :lcsubjects do
      Rake::Task[:environment].invoke
      vocabs = ["http://lcsubjects.org/subjects/sh85118553.nt", 
                "http://lcsubjects.org/subjects/sh85062913.nt", 
                "http://lcsubjects.org/subjects/sh85100849.nt", 
                "http://lcsubjects.org/subjects/sh85082139.nt",
                "http://lcsubjects.org/subjects/sh85029027.nt", 
                "http://lcsubjects.org/subjects/sh98003200.nt"]
      LocalAuthority.harvest_rdf("lcsubjects", vocabs)
    end
  end
end
