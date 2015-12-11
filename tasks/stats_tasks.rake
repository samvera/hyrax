namespace :sufia do
  namespace :stats do
    desc "Cache file view & download stats for all users"
    task user_stats: :environment do
      importer = Sufia::UserStatImporter.new(verbose: true, logging: true)
      importer.import
    end
  end
end
