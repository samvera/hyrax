# frozen_string_literal: true
namespace :hyrax do
  namespace :stats do
    desc "Cache work view, file view & file download stats for all users"
    task user_stats: :environment do
      importer = Hyrax::UserStatImporter.new(verbose: true, logging: true)
      importer.import
    end

    desc "Delete redundant zero-count rows from the stats cache tables (DRY_RUN=true to only report counts, BATCH_SIZE=n rows per batch)"
    task prune_zero_stats: :environment do
      dry_run = ActiveModel::Type::Boolean.new.cast(ENV['DRY_RUN'])
      batch_size = (ENV['BATCH_SIZE'] || 50_000).to_i

      { FileViewStat => :file_id, FileDownloadStat => :file_id, WorkViewStat => :work_id }.each do |klass, id_column|
        Hyrax::StatsPruner.call(klass: klass, id_column: id_column, dry_run: dry_run, batch_size: batch_size)
      end
    end
  end
end
