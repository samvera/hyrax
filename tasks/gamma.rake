require 'rspec/core'
require 'rspec/core/rake_task'
require 'rdf'
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

  namespace :harvest do
    desc "Harvest and map LCSH"
    task :lcsubjects do
      Rake::Task[:environment].invoke
      authority = LocalAuthority.create(:name => "lcsubjects")
      vocabs = ["http://lcsubjects.org/subjects/sh85118553.nt", 
                "http://lcsubjects.org/subjects/sh85062913.nt", 
                "http://lcsubjects.org/subjects/sh85100849.nt", 
                "http://lcsubjects.org/subjects/sh85082139.nt",
                "http://lcsubjects.org/subjects/sh85029027.nt", 
                "http://lcsubjects.org/subjects/sh98003200.nt"]
      vocabs.each do |uri|
        puts "harvesting #{uri}"
        RDF::Reader.open(uri, :format => :ntriples) do |reader|
          reader.each_statement do |statement|
            if statement.predicate == RDF::SKOS.prefLabel
              authority.local_authority_entries.create(:label => statement.object.to_s,
                                                       :uri => statement.subject.to_s)
            end
          end
        end
      end
    end
  end
end
