# frozen_string_literal: true
namespace :hyrax do
  namespace :default_collection_types do
    desc "Create Default Collection Types"
    task create: :environment do
      default = Hyrax::CollectionType.find_or_create_default_collection_type
      admin_set = Hyrax::CollectionType.find_or_create_admin_set_type
      if Hyrax::CollectionType.exists?(machine_id: default.machine_id)
        puts "Default collection type is #{default.machine_id}"
      else
        warn "ERROR: A default collection type did not get created."
      end
      if Hyrax::CollectionType.exists?(machine_id: admin_set.machine_id)
        puts "Default collection type is #{admin_set.machine_id}"
      else
        warn "ERROR: The Admin Set collection type did not get created."
      end
    end
  end
end
