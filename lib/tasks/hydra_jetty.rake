if defined?(Rails.root)
  require "#{Rails.root}/vendor/plugins/hydra-head/lib/hydra/testing_server.rb"
else
  require "hydra/testing_server"
end

# if you would like to see solr startup messages on STDERR
# when starting solr test server during functional tests use:
# 
#    rake SOLR_CONSOLE=true
JETTY_PARAMS = {
  :quiet => ENV['HYDRA_CONSOLE'] ? false : true,
  :jetty_home => ENV['HYDRA_JETTY_HOME'],
  :jetty_port => 8983,
  :solr_home => ENV['HYDRA_SOLR_HOME'],
  :fedora_home => ENV['HYDRA_SOLR_HOME']
}

#:jetty_port => ENV['HYDRA_JETTY_PORT'],
namespace :hydra do
  namespace :jetty do
    desc "Starts the bundled Hydra Testing Server"
    task :start do
      Hydra::TestingServer.configure(JETTY_PARAMS)
      Hydra::TestingServer.instance.start
    end
    
    desc "Stops the bundled Hydra Testing Server"
    task :stop do
      Hydra::TestingServer.instance.stop
    end
    
    desc "Restarts the bundled Hydra Testing Server"
    task :restart do
      Hydra::TestingServer.instance.stop
      Hydra::TestingServer.configure(JETTY_PARAMS)
      Hydra::TestingServer.instance.start
    end

    desc "Copies the default Solr & Fedora configs into the bundled Hydra Testing Server"
    task :config do
      Rake::Task["hydra:jetty:config_fedora"].invoke
      Rake::Task["hydra:jetty:config_solr"].invoke
    end
    
    desc "Copies the default SOLR config for the bundled Hydra Testing Server"
    task :config_solr do
      FileList['solr/conf/*'].each do |f|  
        cp("#{f}", 'jetty/solr/development-core/conf/', :verbose => true)
        cp("#{f}", 'jetty/solr/test-core/conf/', :verbose => true)
    end

    end

    desc "Copies a custom fedora config for the bundled Hydra Testing Server"
    task :config_fedora do
      # load a custom fedora.fcfg - 
      if defined?(Rails.root)
        app_root = Rails.root
      else
        app_root = File.join(File.dirname(__FILE__),"..","..")
      end
       
      fcfg = File.join(app_root,"fedora","conf","fedora.fcfg")
      
      if File.exists?(fcfg)
        puts "copying over fedora.fcfg"
        cp("#{fcfg}", 'jetty/fedora/default/server/config/', :verbose => true)
      else
        puts "#{fcfg} file not found -- skipping fedora config"
      end
    end

    desc "Copies the default SOLR config files and starts up the fedora instance."
    task :load => [:config, :start]

    desc "Returns the status of the Hydra::TestingServer."
    task :status do
      status = Hydra::TestingServer.instance.pid ? "Running: #{Hydra::TestingServer.instance.pid}" : "Not running"
      puts status
    end
  end
end
