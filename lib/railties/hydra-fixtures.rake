# require File.expand_path(File.dirname(__FILE__) + '/hydra_jetty.rb')
require "active-fedora"
require "solrizer-fedora"
require "active_support" # This is just to load ActiveSupport::CoreExtensions::String::Inflections
require "hydra/fixture_loader"
namespace :hydra do
  
  
  desc "Delete and re-import the fixture identified by pid" 
  task :refresh_fixture => :init do
    # If a destination url has been provided, attampt to export from the fedora repository there.
    if ENV["destination"]
      Fedora::Repository.register(ENV["destination"])
    end
    if ENV["pid"].nil? 
      raise "You must specify a valid pid.  Example: rake hydra:refresh_fixture pid=demo:12"
    end
    begin
      ActiveFedora::FixtureLoader.new('test_support/fixtures').reload(ENV["pid"])
    rescue Errno::ECONNREFUSED => e
      puts "Can't connect to Fedora! Are you sure jetty is running?"
    rescue Exception => e
        logger.error("Received a Fedora error while loading #{pid}\n#{e}")
    end
  end
  
  desc "Delete the object identified by pid. Example: rake hydra:delete pid=demo:12"
  task :delete => :init do
    # If a destination url has been provided, attampt to export from the fedora repository there.
    if ENV["destination"]
      Fedora::Repository.register(ENV["destination"])
    end
    
    if ENV["pid"].nil? 
      raise "You must specify a valid pid.  Example: rake hydra:delete pid=demo:12"
    else
      pid = ENV["pid"]
      puts "Deleting '#{pid}' from #{ActiveFedora::RubydoraConnection.instance.options[:url]}"
      begin
        ActiveFedora::FixtureLoader.delete(pid)
      rescue Errno::ECONNREFUSED => e
        puts "Can't connect to Fedora! Are you sure jetty is running?"
      rescue Exception => e
        logger.error("Received a Fedora error while deleting #{pid}\n#{e}")
      end
      logger.info "Deleted '#{pid}' from #{ActiveFedora::RubydoraConnection.instance.options[:url]}"
    end
  end
  
  desc "Delete a range of objects in a given namespace.  ie 'rake hydra:purge_range[demo, 22, 50]' will delete demo:22 through demo:50"
  task :purge_range => :init do |t, args|
    # If Fedora Repository connection is not already initialized, initialize it using ActiveFedora defaults
    # ActiveFedora.init unless Thread.current[:repo]
    
    namespace = ENV["namespace"]
    start_point = ENV["start"].to_i
    stop_point = ENV["stop"].to_i
    unless start_point < stop_point 
      raise StandardError "start point must be less that end point."
    end
    puts "Deleting #{stop_point - start_point} objects from #{namespace}:#{start_point.to_s} to #{namespace}:#{stop_point.to_s}"
    i = start_point
    while i <= stop_point do
      pid = namespace + ":" + i.to_s
      begin
        ActiveFedora::Base.load_instance(pid).delete
      rescue ActiveFedora::ObjectNotFoundError
        # The object has already been deleted (or was never created).  Do nothing.
      end
      puts "Deleted '#{pid}' from #{Fedora::Repository.instance.fedora_url}"
      i += 1
    end
  end

  namespace :fixtures do
    desc "Refresh the fixtures applicable to this hydra head"
    task :refresh => ["hydra:default_fixtures:refresh"] do
    end
  end
  
  desc "Export the object identified by pid into test_support/fixtures. Example:rake hydra:harvest_fixture pid=druid:sb733gr4073 source=http://fedoraAdmin:fedoraAdmin@127.0.0.1:8080/fedora"
  task :harvest_fixture => :init do
        
    # If a source url has been provided, attampt to export from the fedora repository there.
    if ENV["source"]
      Fedora::Repository.register(ENV["source"])
    end
    
    if ENV["pid"].nil? 
      puts "You must specify a valid pid.  Example: rake hydra:harvest_fixture pid=demo:12"
    else
      pid = ENV["pid"]
      puts "Exporting '#{pid}' from #{Fedora::Repository.instance.fedora_url}"
      foxml = Fedora::Repository.instance.export(pid)
      filename = File.join("test_support","fixtures","#{pid.gsub(":","_")}.foxml.xml")
      file = File.new(filename,"w")
      file.syswrite(foxml)
      puts "The object has been saved as #{filename}"
    end
  end
  
  desc "Import the fixture located at the provided path. Example: rake hydra:import_fixture fixture=test_support/fixtures/demo_12.foxml.xml"
  task :import_fixture => [:init] do
    
    # If a destination url has been provided, attampt to export from the fedora repository there.
    if ENV["destination"]
      Fedora::Repository.register(ENV["destination"])
    end
    if !ENV["fixture"].nil? 
      body = ActiveFedora::FixtureLoader.import_to_fedora(ENV["fixture"])
    elsif !ENV["pid"].nil?
      body = ActiveFedora::FixtureLoader.new('test_support/fixtures').import_and_index(ENV["pid"])
    else
      raise "You must specify a path to the fixture or provide its pid.  Example: rake hydra:import_fixture fixture=test_support/fixtures/demo_12.foxml.xml"
    end
    puts "The fixture has been ingested as #{body}"
    
  end
  
  desc "Init Hydra configuration" 
  task :init => [:environment] do
    # We need to just start rails so that all the models are loaded
  end

  desc "Load hydra-head models"
  task :load_models do
    require "hydra"
    Dir.glob(File.join(File.expand_path(File.dirname(__FILE__)), "..",'app','models', '*.rb')).each do |model|
      load model
    end
  end

  namespace :default_fixtures do

    FIXTURES = [
        "hydrangea:fixture_mods_article1",
        "hydrangea:fixture_mods_article3",
        "hydrangea:fixture_file_asset1",
        "hydrangea:fixture_mods_article2",
        "hydrangea:fixture_uploaded_svg1",
        "hydrangea:fixture_archivist_only_mods_article",
        "hydrangea:fixture_mods_dataset1",
        "libra-oa:1", "libra-oa:2", "libra-oa:7",
        "hydrus:admin_class1",
        "hydra:test_generic_content",
        "hydra:test_generic_image",
        "hydra:test_default_partials",
        "hydra:test_no_model"
    ]

    desc "Load default Hydra fixtures"
    task :load do
      FIXTURES.each do |fixture|
        ENV["fixture"] = nil
        ENV["pid"] = fixture
        Rake::Task["hydra:import_fixture"].reenable
        Rake::Task["hydra:import_fixture"].invoke
      end
    end

    desc "Remove default Hydra fixtures"
    task :delete do
      FIXTURES.each do |fixture|
        ENV["fixture"] = nil
        ENV["pid"] = fixture
        Rake::Task["hydra:delete"].reenable
        Rake::Task["hydra:delete"].invoke
      end
    end

    desc "Refresh default Hydra fixtures"
    task :refresh do
      FIXTURES.each do |fixture|
        logger.debug("Refreshing #{fixture}")
        ENV["fixture"] = nil
        ENV["pid"] = fixture        
        Rake::Task["hydra:delete"].reenable
        Rake::Task["hydra:delete"].invoke
        Rake::Task["hydra:import_fixture"].reenable
        Rake::Task["hydra:import_fixture"].invoke
      end
    end
  end

end
