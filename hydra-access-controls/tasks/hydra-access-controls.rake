namespace "hydra-access" do
  desc "Run Continuous Integration"
  task :ci do
    ENV['environment'] = "test"
    solr_params = { port: 8985, verbose: true, managed: true }
    fcrepo_params = { port: 8986, verbose: true, managed: true,
                      no_jms: true, fcrepo_home_dir: 'fcrepo4-test-data' }
    SolrWrapper.wrap(solr_params) do |solr|
      solr.with_collection(name: 'hydra-test', dir: File.join(File.expand_path("../..", File.dirname(__FILE__)), "solr", "config")) do
        FcrepoWrapper.wrap(fcrepo_params) do
          Rake::Task['spec'].invoke
        end
      end
    end
  end
end
