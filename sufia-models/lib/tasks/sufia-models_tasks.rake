namespace :solr do
  desc "Enqueue a job to resolrize the repository objects"
  task reindex: :environment do
    CurationConcerns.queue.push(ResolrizeJob.new)
  end
end
