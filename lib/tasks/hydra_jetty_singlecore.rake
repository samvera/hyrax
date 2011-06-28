require 'jettywrapper'

namespace :hydra do
  namespace :jetty do
    
    dev = {
      :jetty_home => File.expand_path("#{File.dirname(__FILE__)}/../../jetty-dev"),
      :jetty_port => "8983"
    }

    test = {
      :jetty_home => File.expand_path("#{File.dirname(__FILE__)}/../../jetty-test"),
      :jetty_port => "8984"
    }
    
    namespace :status do
      
      desc "Return the status of jetty-dev"
      task :dev do
        status = Jettywrapper.is_running?(dev) ? "Running: #{Jettywrapper.pid(dev)}" : "Not running"
        puts status
      end
      
      desc "Return the status of jetty-test"
      task :test do
        status = Jettywrapper.is_running?(test) ? "Running: #{Jettywrapper.pid(test)}" : "Not running"
        puts status
      end
      
    end

    
    desc "Starts the bundled jetty"
    task :start => [:init] do
      if Rails.env.development? 
        jetty_home = JETTY_HOME_DEV
        devinstance = Jettywrapper.start_with_params(JETTY_PARAMS_DEV)
        puts "Started at PID #{Jettywrapper.instance.pid}"
      elsif Rails.env.test?
        jetty_home = JETTY_HOME_TEST
        Jettywrapper.configure(JETTY_PARAMS_TEST)
        Jettywrapper.instance.start
        puts "Started at PID #{Jettywrapper.instance.pid}"
      end
    end
    
    desc "Stops the bundled Hydra Testing Server"
    task :stop do
      Jettywrapper.instance.stop
    end
    
    desc "Restarts the bundled Hydra Testing Server"
    task :restart do
      Jettywrapper.instance.stop
      Jettywrapper.configure(JETTY_PARAMS)
      Jettywrapper.instance.start
    end

    desc "Init Hydra configuration" 
    task :init => [:environment] do
      if !ENV["environment"].nil? 
        RAILS_ENV = ENV["environment"]
      end
      
      JETTY_HOME_TEST = File.expand_path(File.dirname(__FILE__) + '/../../jetty-test')
      JETTY_HOME_DEV = File.expand_path(File.dirname(__FILE__) + '/../../jetty-dev')
      
      JETTY_PARAMS_TEST = {
        :quiet => ENV['HYDRA_CONSOLE'] ? false : true,
        :jetty_home => JETTY_HOME_TEST,
        :jetty_port => 8983,
        :solr_home => File.expand_path(JETTY_HOME_TEST + '/solr'),
        :fedora_home => File.expand_path(JETTY_HOME_TEST + '/fedora/default')
      }

      JETTY_PARAMS_DEV = {
        :quiet => ENV['HYDRA_CONSOLE'] ? false : true,
        :jetty_home => JETTY_HOME_DEV,
        :jetty_port => 8984,
        :solr_home => File.expand_path(JETTY_HOME_DEV + '/solr'),
        :fedora_home => File.expand_path(JETTY_HOME_DEV + '/fedora/default')
      }
      
      # If Fedora Repository connection is not already initialized, initialize it using ActiveFedora defaults
      ActiveFedora.init unless Thread.current[:repo]  
    end

    desc "Copies the default SOLR config for the bundled jetty"
    task :config_solr => [:init] do
      FileList['solr/conf/*'].each do |f|  
        cp("#{f}", JETTY_PARAMS_TEST[:solr_home] + '/conf/', :verbose => true)
        cp("#{f}", JETTY_PARAMS_DEV[:solr_home] + '/conf/', :verbose => true)
      end
    end
    
    desc "Copies a custom fedora config for the bundled jetty"
    task :config_fedora => [:init] do
      fcfg = 'fedora/conf/fedora.fcfg'
      if File.exists?(fcfg)
        puts "copying over fedora.fcfg"
        cp("#{fcfg}", JETTY_PARAMS_TEST[:fedora_home] + '/server/config/', :verbose => true)
        cp("#{fcfg}", JETTY_PARAMS_DEV[:fedora_home] + '/server/config/', :verbose => true)
      else
        puts "#{fcfg} file not found -- skipping fedora config"
      end
    end
    
    desc "Copies the default Solr & Fedora configs into the bundled jetty"
    task :config do
      Rake::Task["hydra:jetty:config_fedora"].invoke
      Rake::Task["hydra:jetty:config_solr"].invoke
    end

  end
end