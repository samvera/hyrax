namespace :curation_concerns do
  namespace :solr do
    desc "Enqueue a job to resolrize the repository objects"
    task reindex: :environment do
      ResolrizeJob.perform_later
    end
  end
end
