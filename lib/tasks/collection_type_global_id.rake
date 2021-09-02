# frozen_string_literal: true
namespace :hyrax do
  namespace :collections do
    desc 'Update CollectionType global id references for Hyrax 3.0.0'
    task update_collection_type_global_ids: :environment do
      puts 'Updating collection -> collection type GlobalId references.'

      count = 0

      Collection.all.each do |collection|
        next if collection.collection_type_gid == collection.collection_type.to_global_id.to_s

        collection.public_send(:collection_type_gid=, collection.collection_type.to_global_id, force: true)

        collection.save &&
          count += 1
      end

      puts "Updated #{count} collections."
    end
  end
end
