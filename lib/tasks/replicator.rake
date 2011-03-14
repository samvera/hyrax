namespace :replicator do
  
  desc 'Copy a fedora object of the given pid.'
  task :copy_object => :environment do 
    if ENV['PID']
      replicator = Solrizer::Replicator.new
      replicator.replicate_object(ENV['PID'])
    else
      puts "You must provide a pid using the format 'replicator::copy_object PID=sample:pid'."
    end
  end
  
  desc 'Copy all objects in the repository.'
  task :copy_objects => :environment do
  
    if ENV['REPLICATOR_LIST']
      REPLICATOR_LIST = ENV['REPLICATOR_LIST']
    end
  
    replicator = Solrizer::Replicator.new
    puts "Source URL: #{ActiveFedora.fedora_config[:url]}"
    puts "Destination URL: #{replicator.configs["destination"]["fedora"]["url"]}"
    replicator.replicate_objects
    puts "Replicator task complete."
  end
  
end