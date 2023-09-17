# frozen_string_literal: true
namespace :hyrax do
  namespace :collections do
    desc 'Update CollectionType global id references for Hyrax 3.0.0'
    task update_collection_type_global_ids: :environment do
      puts 'Updating collection -> collection type GlobalId references.'

      count = 0

      Hyrax.query_service.find_all_of_model(model: Hyrax::PcdmCollection).each do |collection|
        type = Hyrax::CollectionType.find_by_gid(collection.collection_type_gid)
        next if collection.collection_type_gid == type.to_global_id.to_s

        # Awful hack to allow converted AF collections to force update collection_type_gid
        Thread.current[:force_collection_type_gid] = true
        collection.collection_type_gid = type.to_global_id

        Hyrax.persister.save(resource: collection) &&
          count += 1
      ensure
        Thread.current[:force_collection_type_gid] = false
      end

      puts "Updated #{count} collections."
    end
  end
end
