namespace :hyrax do
  namespace :migrate do
    task move_all_works_to_admin_set: :environment do
      require 'hyrax/move_all_works_to_admin_set'
      MoveAllWorksToAdminSet.run(AdminSet.find(AdminSet::DEFAULT_ID))
    end
    desc "Move membership from collection#members work#member_of_collections"
    task collections: :environment do
      require 'hyrax/collections_migration'
      Hyrax::CollectionsMigration.run
    end
  end
end
