SOLR_PARAMS = {
  :quiet => ENV['SOLR_CONSOLE'] ? false : true,
  :jetty_home => ENV['SOLR_JETTY_HOME'] || File.expand_path('./jetty'),
  :jetty_port => ENV['SOLR_JETTY_PORT'] || 8983,
  :solr_home => ENV['SOLR_HOME'] || File.expand_path('./jetty/solr')
}
namespace :local do
  desc "Invokes Application level rspec tests wrapped in the TestSolrServer"
  task :spec do
    error = TestSolrServer.wrap(SOLR_PARAMS) do
      Rake::Task["rake:spec"].invoke 
    end
    raise "test failures: #{error}" if error
  end
  
  desc "Invokes Applicatino level cucumber features wrapped in the TestSolrServer"
  task :cucumber do
    error = TestSolrServer.wrap(SOLR_PARAMS) do
      Rake::Task["cucumber"].invoke 
    end
    raise "test failures: #{error}" if error
  end
end
