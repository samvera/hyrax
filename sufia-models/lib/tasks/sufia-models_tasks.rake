# Pull in tasks from AF::Noid
af_noid = Gem::Specification.find_by_name 'active_fedora-noid'
load "#{af_noid.gem_dir}/lib/tasks/noid_tasks.rake"

namespace :solr do
  desc "Enqueue a job to resolrize the repository objects"
  task reindex: :environment do
    ResolrizeJob.perform_later
  end
end

namespace :sufia do
  namespace :noid do
    desc 'Migrate minter state file'
    task migrate_statefile: :environment do
      ENV['AFNOID_STATEFILE'] = Sufia.config.minter_statefile
      Rake::Task['active_fedora:noid:migrate_statefile'].invoke if needs_migration?(Sufia.config.minter_statefile)
    end
  end

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

def needs_migration?(statefile)
  !!YAML.load(File.open(statefile).read)
rescue Psych::SyntaxError, Errno::ENOENT
  false
end
