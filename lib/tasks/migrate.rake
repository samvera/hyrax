namespace :sufia do
  namespace :migrate do
    task move_all_works_to_admin_set: :environment do
      require 'sufia/move_all_works_to_admin_set'
      MoveAllWorksToAdminSet.run(AdminSet.find(Sufia::DefaultAdminSetActor::DEFAULT_ID))
    end
  end
end
