require 'jettywrapper'
require 'fileutils'

namespace :hydra do
  namespace :jetty do
    
    dev_jetty_home = File.expand_path("#{File.dirname(__FILE__)}/../../jetty-dev")
    DEV = {
      :jetty_home => dev_jetty_home,
      :jetty_port => "8983",
      :solr_home => File.expand_path("#{dev_jetty_home}/solr"),
      :fedora_home => File.expand_path("#{dev_jetty_home}/fedora/default")
    }

    test_jetty_home = File.expand_path("#{File.dirname(__FILE__)}/../../jetty-test")
    TEST = {
      :jetty_home => test_jetty_home,
      :jetty_port => "8984",
      :solr_home => File.expand_path("#{test_jetty_home}/solr"),
      :fedora_home => File.expand_path("#{test_jetty_home}/fedora/default")
    }
    
    task :copy do
      FileUtils.cp_r(test_jetty_home, dev_jetty_home, :verbose => true)
    end
      
    namespace :config do
      desc "Configure solr and fedora for dev and test"
      task :all => [:solr, :fedora] do
      end
      
      desc "Copy solr configuration files to jetty-dev and jetty-test"
      task :solr do
        FileList['solr/conf/*'].each do |f|  
          cp("#{f}", DEV[:solr_home] + '/conf/', :verbose => true)
          cp("#{f}", TEST[:solr_home] + '/conf/', :verbose => true)
        end
      end
      
      desc "Copy fedora configuration files to jetty-dev and jetty-test"
      task :fedora do
        fcfg = 'fedora/conf/fedora.fcfg'
        if File.exists?(fcfg)
          puts "copying over fedora.fcfg"
          cp("#{fcfg}", DEV[:fedora_home] + '/server/config/', :verbose => true)
          cp("#{fcfg}", TEST[:fedora_home] + '/server/config/', :verbose => true)
        else
          puts "#{fcfg} file not found -- skipping fedora config"
        end
      end
    end
    
    namespace :status do
      
      desc "Return the status of both jetty-dev and jetty-test"
      task :all do
        dev_status = Jettywrapper.is_jetty_running?(DEV) ? "jetty-dev is running: #{Jettywrapper.pid(DEV)}" : "jetty-dev is not running"
        test_status = Jettywrapper.is_jetty_running?(TEST) ? "jetty-test is running: #{Jettywrapper.pid(TEST)}" : "jetty-test is not running"
        puts dev_status
        puts test_status
      end
      
      desc "Return the status of jetty-dev"
      task :dev do
        status = Jettywrapper.is_jetty_running?(DEV) ? "Running: #{Jettywrapper.pid(DEV)}" : "Not running"
        puts status
      end
      
      desc "Return the status of jetty-test"
      task :test do
        status = Jettywrapper.is_jetty_running?(TEST) ? "Running: #{Jettywrapper.pid(TEST)}" : "Not running"
        puts status
      end
      
    end

    namespace :start do
      
      desc "Start jetty-dev"
      task :dev do
        Jettywrapper.start(DEV)
        puts "jetty-dev started at PID #{Jettywrapper.pid(DEV)}"
      end
      
      desc "Start jetty-test"
      task :test do
        Jettywrapper.start(TEST)
        puts "jetty-test started at PID #{Jettywrapper.pid(TEST)}"
      end
    
    end
    
    namespace :stop do
    
      desc "Stop jetty-dev"
      task :dev do
        Jettywrapper.stop(DEV)
        puts "Stopping jetty-dev"
      end
      
      desc "Stop jetty-test"
      task :test do
        Jettywrapper.stop(TEST)
        puts "Stopping jetty-test"
      end
    
    end
    
    namespace :restart do
      desc "Restart jetty-dev"
      task :dev do
        puts "jetty-dev is running at PID #{Jettywrapper.pid(DEV)}"
        Jettywrapper.stop(DEV)
        sleep 10
        Jettywrapper.start(DEV)
        puts "Restarting jetty-dev"
        puts "jetty-dev is running at PID #{Jettywrapper.pid(DEV)}"
      end
      
      desc "Restart jetty-test"
      task :test do
        puts "jetty-test is running at PID #{Jettywrapper.pid(TEST)}"
        Jettywrapper.stop(TEST)
        sleep 10
        Jettywrapper.start(TEST)
        puts "Restarting jetty-test"
        puts "jetty-test is running at PID #{Jettywrapper.pid(TEST)}"
      end
    end
  end
end