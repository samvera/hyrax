namespace :sufia do
  namespace :default_admin_set do
    desc "Create the default Admin Set"
    task create: :environment do
      Sufia::AdminSetCreateService.create_default!
    end
  end
end
