namespace :hyrax do
  namespace :default_collection_type do
    desc "Create the Default Collection Type"
    task create: :environment do
      ct = Hyrax::CollectionType.find_or_create_default_collection_type
      if Hyrax::CollectionType.exists?(machine_id: ct.machine_id)
        puts "Default collection type is #{ct.machine_id}"
      else
        $stderr.puts "ERROR: A default collection type did not get created."
      end
    end
  end
end
