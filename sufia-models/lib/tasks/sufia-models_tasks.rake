namespace :solr do
  desc "Enqueue a job to resolrize the repository objects"
  task reindex: :environment do
    ResolrizeJob.perform_later
  end
end

namespace :sufia do
  namespace :user do
    desc 'Populate user tokens'
    task tokens: :environment do
      unless Sufia.config.arkivo_api
        puts "Zotero integration is not enabled"
        next
      end
      User.where(arkivo_token: nil).each do |user|
        user.set_arkivo_token
        user.save
      end
    end
  end
end
