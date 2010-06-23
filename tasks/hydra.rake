# require File.expand_path(File.dirname(__FILE__) + '/hydra_jetty.rb')

namespace :hydra do
  
  desc "Delete the object identified by pid"
  task :delete => :environment do
    # If a destination url has been provided, attampt to export from the fedora repository there.
    if ENV["destination"]
      Fedora::Repository.register(ENV["destination"])
    end
    
    # If Fedora Repository connection is not already initialized, initialize it using ActiveFedora defaults
    ActiveFedora.init unless Thread.current[:repo]
    
    if ENV["pid"].nil? 
      puts "You must specify a valid pid.  Example: rake hydra:delete pid=demo:12"
    else
      pid = ENV["pid"]
      puts "Deleting '#{pid}' from #{Fedora::Repository.instance.fedora_url}"
      ActiveFedora::Base.load_instance(pid).delete
      puts "The object has been deleted."
    end
  end
  
  desc "Export the object identified by pid into spec/fixtures. Example:rake hydra:harvest_fixture pid=druid:sb733gr4073 source=http://fedoraAdmin:fedoraAdmin@127.0.0.1:8080/fedora"
  task :harvest_fixture => :environment do
        
    # If a source url has been provided, attampt to export from the fedora repository there.
    if ENV["source"]
      Fedora::Repository.register(ENV["source"])
    end
    
    # If Fedora Repository connection is not already initialized, initialize it using ActiveFedora defaults
    ActiveFedora.init unless Thread.current[:repo]
    
    if ENV["pid"].nil? 
      puts "You must specify a valid pid.  Example: rake hydra:harvest_fixture pid=demo:12"
    else
      pid = ENV["pid"]
      puts "Exporting '#{pid}' from #{Fedora::Repository.instance.fedora_url}"
      foxml = Fedora::Repository.instance.export(pid)
      filename = File.join("spec","fixtures","#{pid.gsub(":","_")}.foxml.xml")
      file = File.new(filename,"w")
      file.syswrite(foxml)
      puts "The object has been saved as #{filename}"
    end
  end
  
  desc "Import the fixture located at the provided path"
  task :import_fixture => :environment do
        
    # If a destination url has been provided, attampt to export from the fedora repository there.
    if ENV["destination"]
      Fedora::Repository.register(ENV["destination"])
    end
    
    # If Fedora Repository connection is not already initialized, initialize it using ActiveFedora defaults
    ActiveFedora.init unless Thread.current[:repo]
    
    if !ENV["pid"].nil?
      pid = ENV["pid"]
      filename = File.join("spec","fixtures","#{pid.gsub(":","_")}.foxml.xml")
    elsif !ENV["fixture"].nil? 
      filename = ENV["fixture"]
    else
      puts "You must specify a path to the fixture or provide its pid.  Example: rake hydra:import_fixture fixture=spec/fixtures/demo_12.foxml.xml"
    end
    
    if !filename.nil?
      puts "Importing '#{filename}' to #{Fedora::Repository.instance.fedora_url}"
      file = File.new(filename, "r")
      result = foxml = Fedora::Repository.instance.ingest(file.read)
      if result
        puts "The fixture has been ingested as #{result}"
        if !pid.nil?
          solrizer = Solrizer::Solrizer.new 
          solrizer.solrize(pid) 
        end    
      else
        puts "Failed to ingest the fixture."
      end
    end    
    
  end

end