# frozen_string_literal: true
namespace :hyrax do
  namespace :stats do
    desc "Cache work view, file view & file download stats for all users"
    task user_stats: :environment do
      importer = Hyrax::UserStatImporter.new(verbose: true, logging: true)
      importer.import
    end
  end
end
