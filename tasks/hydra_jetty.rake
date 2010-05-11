# if you would like to see solr startup messages on STDERR
# when starting solr test server during functional tests use:
# 
#    rake SOLR_CONSOLE=true
#require 'hydra/testing_server'


JETTY_PARAMS = {
  :quiet => ENV['HYDRA_CONSOLE'] ? false : true,
  :jetty_home => ENV['HYDRA_JETTY_HOME'],
  :jetty_port => ENV['HYDRA_JETTY_PORT'],
  :solr_home => ENV['HYDRA_SOLR_HOME'],
  :fedora_home => ENV['HYDRA_SOLR_HOME']
}

namespace :hydra do
namespace :jetty do
  desc "Starts the bundled Hydra Testing Server"
  task :start do
    Hydra::TestingServer.configure(JETTY_PARAMS)
    Hydra::TestingServer.instance.start
  end
  
  desc "Stops the bundled Hydra Testing Server"
  task :stop do
    puts "stopping #{Hydra::TestingServer.instance.pid}"
    Hydra::TestingServer.instance.stop
  end
end
end