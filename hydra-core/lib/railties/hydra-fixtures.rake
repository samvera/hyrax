namespace :hydra do
  
  desc "Init Hydra configuration" 
  task :init => [:environment] do
    # We need to just start rails so that all the models are loaded
  end

  desc "Load hydra-head models"
  task :load_models do
    Dir.glob(File.join(File.expand_path(File.dirname(__FILE__)), "..",'app','models', '*.rb')).each do |model|
      load model
    end
  end

  namespace :fixtures do
    task :load do
      ENV["dir"] ||= File.join("spec", "fixtures")
      loader = ActiveFedora::FixtureLoader.new(ENV['dir'])
      Dir.glob("#{ENV['dir']}/*.foxml.xml").each do |fixture_path|
        pid = File.basename(fixture_path, ".foxml.xml").sub("_",":")
        begin
          foo = loader.reload(pid)
          puts "Updated #{pid}"
        rescue Errno::ECONNREFUSED => e
          puts "Can't connect to Fedora! Are you sure jetty is running? (#{ActiveFedora::Base.connection_for_pid(pid).inspect})"
        rescue Exception => e
          puts("Received a Fedora error while loading #{pid}\n#{e}")
          logger.error("Received a Fedora error while loading #{pid}\n#{e}")
        end
      end
    end

    desc "Remove default Hydra fixtures"
    task :delete do
      ENV["dir"] ||= File.join("spec", "fixtures")
      loader = ActiveFedora::FixtureLoader.new(ENV['dir'])
      Dir.glob("#{ENV['dir']}/*.foxml.xml").each do |fixture_path|
        ENV["pid"] = File.basename(fixture_path, ".foxml.xml").sub("_",":")
        Rake::Task["repo:delete"].reenable
        Rake::Task["repo:delete"].invoke
      end
    end

    desc "Refresh default Hydra fixtures"
    task :refresh => [:delete, :load]

  end
end
  
