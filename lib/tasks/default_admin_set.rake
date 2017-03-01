namespace :hyrax do
  namespace :default_admin_set do
    desc "Create the Default Admin Set"
    task create: :environment do
      AdminSet.find_or_create_default_admin_set_id
    end
  end
end
