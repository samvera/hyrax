namespace :hydra do
  namespace :jetty do

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
      puts JETTY_PARAMS_TEST
      puts JETTY_PARAMS_DEV
    end

    desc "Copies the default SOLR config for the bundled jetty"
    task :config_solr => [:init] do
      FileList['solr/conf/*'].each do |f|  
        cp("#{f}", JETTY_PARAMS_TEST[:solr_home] + '/conf/', :verbose => true)
        cp("#{f}", JETTY_PARAMS_DEV[:solr_home] + '/conf/', :verbose => true)
      end
    end

  end
end