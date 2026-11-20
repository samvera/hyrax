# frozen_string_literal: true

namespace :hyrax do
  namespace :orphans do
    desc 'Report orphaned file sets and stray index documents; pass [delete] to remove them'
    task :cleanup, [:mode] => :environment do |_task, args|
      delete = args[:mode] == 'delete'
      result = Hyrax::OrphanCleanupService.new(delete: delete, logger: Logger.new($stdout)).call

      verb = delete ? 'Removed' : 'Found'
      puts "#{verb} #{result[:file_set_ids].count} orphaned file sets and #{result[:index_ids].count} stray index documents."
      puts "Could not destroy #{result[:failed_file_set_ids].count} orphaned file sets; see the log." if result[:failed_file_set_ids].any?
      puts 'Run rake "hyrax:orphans:cleanup[delete]" to remove them.' unless delete
    end
  end
end
