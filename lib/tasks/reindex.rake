# frozen_string_literal: true
namespace :solr do
  desc "Enqueue a job to resolrize the repository objects"
  task reindex: :environment do
    ResolrizeJob.perform_later
  end
end
