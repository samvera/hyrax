namespace :hyrax do
  namespace :migrate do
    task move_all_works_to_admin_set: :environment do
      require 'hyrax/move_all_works_to_admin_set'
      MoveAllWorksToAdminSet.run(AdminSet.find(Hyrax::DefaultAdminSetActor::DEFAULT_ID))
    end
  end
end
