namespace :hyrax do
  namespace :default_admin_set do
    desc "Create the Default Admin Set"
    task create: :environment do
      AdminSet.create_default!
    end
  end
end