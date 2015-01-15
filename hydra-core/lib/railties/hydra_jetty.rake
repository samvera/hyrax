namespace :jetty do
  desc "Apply all configs to Testing Server (relies on hydra:jetty:config tasks unless you override it)"
  task :config do
    Rake::Task["hydra:jetty:config"].invoke
  end
end

namespace :hydra do
  namespace :jetty do
    desc "Copies the default Solr config into the bundled Hydra Testing Server"
    task :config do
      Rake::Task["hydra:jetty:config_solr"].invoke
    end

    desc "Copies the contents of solr_conf into the Solr development-core and test-core of Testing Server"
    task :config_solr do
      FileList['solr_conf/conf/*'].each do |f|
        cp("#{f}", 'jetty/solr/development-core/conf/', :verbose => true)
        cp("#{f}", 'jetty/solr/test-core/conf/', :verbose => true)
      end
    end

    desc "Copies the default SOLR config files and starts up the fedora instance."
    task :load => [:config, 'jetty:start']
  end
end
