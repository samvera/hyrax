# frozen_string_literal: true

# Thin wrappers: the work lives in Hyrax::S3Migration::* and the MigrateFilesToS3Job /
# MigrateFileSetToS3Job jobs. See documentation/migrating-files-to-s3.md.
# rubocop:disable Metrics/BlockLength, Metrics/MethodLength, Metrics/AbcSize
namespace :hyrax do
  namespace :migrate do
    def s3_migration_flag(name, default: 'false')
      ActiveModel::Type::Boolean.new.cast(ENV.fetch(name, default))
    end

    def s3_migration_require_s3!
      abort 'Set up the :repository_s3 Valkyrie storage adapter first (see documentation/migrating-files-to-s3.md).' unless Valkyrie::StorageAdapter.storage_adapters.key?(:repository_s3)
    end

    def s3_migration_each_original(limit: ENV['LIMIT']&.to_i, progress: nil)
      done = 0
      Hyrax::S3Migration.each_file_set do |file_set|
        break if limit && done >= limit

        progress&.tick

        original = Hyrax.custom_queries.find_original_file(file_set:)
        next unless original

        done += 1 if yield(file_set, original)
      end
    end

    def s3_migration_inline(dry_run:)
      counts = Hash.new(0)
      progress = Hyrax::S3Migration::Progress.new(detail: -> { counts.map { |status, count| "#{status}: #{count}" }.join('  ') })
      s3_migration_each_original(progress:) do |file_set, original|
        result = Hyrax::S3Migration::FileMigrator.new(file_set:, original:, dry_run:).call
        counts[result.status] += 1
        next false if result.status == :already_migrated

        puts "  #{result.status.to_s.upcase} #{file_set.id} #{result.message}".rstrip
        true
      rescue StandardError => e
        counts[:error] += 1
        puts "  ERROR #{file_set.id} - #{e.class}: #{e.message}"
        true
      end
      puts "\nExamined #{counts.values.sum} file sets. #{counts.map { |status, count| "#{status}: #{count}" }.join('  ')}".strip
      puts 'No file sets were found; check the model names and query services.' if counts.empty?
    end

    desc <<~DESC
      Move disk-stored original files (disk:// ids) to the :repository_s3 storage adapter. By default this
      enqueues jobs (one per file set; set S3_MIGRATION_QUEUE to use a dedicated queue). Each upload is
      verified by SHA-256 read-back, and against the stored characterization checksum, before the identifier
      is switched; the disk copy is never touched.
      Env: DRY_RUN=true runs inline and only reports; INLINE=true runs inline for real; LIMIT=<n> files.
    DESC
    task files_to_s3: :environment do
      s3_migration_require_s3!
      dry_run = s3_migration_flag('DRY_RUN')

      if dry_run || s3_migration_flag('INLINE')
        puts "[DRY RUN] No changes will be made.\n\n" if dry_run
        s3_migration_inline(dry_run:)
      else
        MigrateFilesToS3Job.perform_later(limit: ENV['LIMIT']&.to_i)
        puts 'Enqueued MigrateFilesToS3Job'
      end
    end

    desc <<~DESC
      Read-only audit of originals already in S3: object readable, recorded size and stored checksum match.
      Get zero problems before deleting anything from disk. Env: LIMIT=<n> files.
    DESC
    task verify_s3_files: :environment do
      counts = Hash.new(0)
      progress = Hyrax::S3Migration::Progress.new(detail: -> { counts.map { |status, count| "#{status}: #{count}" }.join('  ') })
      s3_migration_each_original(progress:) do |file_set, original|
        result = Hyrax::S3Migration::Auditor.new(original:).call
        counts[result.status] += 1
        next false if result.status == :not_in_s3

        puts "  PROBLEM #{file_set.id} - #{result.problems.join('; ')}" if result.status == :problem
        true
      rescue StandardError => e
        counts[:problem] += 1
        puts "  PROBLEM #{file_set.id} - #{e.class}: #{e.message}"
        true
      end
      puts "\nOK: #{counts[:ok]}  Problems: #{counts[:problem]}  Not yet in S3: #{counts[:not_in_s3]}"
    end

    desc 'Read-only report of file storage by file use and scheme (disk, shrine, ...).'
    task report_file_storage: :environment do
      puts "use | scheme | files | GB"
      Hyrax::S3Migration::StorageReport.call(progress: Hyrax::S3Migration::Progress.new).sort.each do |(use, scheme), (count, bytes)|
        puts "#{use} | #{scheme} | #{count} | #{(bytes / 1e9).round(2)}"
      end
    end

    def s3_migration_run_quarantine(label, action)
      counts = Hash.new(0)
      progress = Hyrax::S3Migration::Progress.new(detail: -> { counts.map { |status, count| "#{status}: #{count}" }.join('  ') })
      Hyrax::S3Migration::Manifest.new.each_entry do |entry|
        progress.tick
        quarantine = Hyrax::S3Migration::Quarantine.new(entry, apply: s3_migration_flag('APPLY'),
                                                               verify_sha: s3_migration_flag('VERIFY_SHA', default: 'true'))
        status = quarantine.public_send(action)
        counts[status] += 1
        puts "  #{label} #{entry[:file_set_id]}" if %i[quarantined rolled_back].include?(status)
      rescue StandardError => e
        counts[:error] += 1
        puts "  ERROR #{entry[:file_set_id]} - #{e.class}: #{e.message}"
      end
      puts "\n#{counts.map { |status, count| "#{status}: #{count}" }.join('  ')}".strip
      puts 'No manifest entries found.' if counts.empty?
    end

    desc <<~DESC
      Move the disk copies of manifested files to <storage>/.quarantine after re-checking the database
      and the S3 object against the manifest. Dry run unless APPLY=true. VERIFY_SHA=false skips the hash.
    DESC
    task quarantine_disk_files: :environment do
      s3_migration_require_s3!
      puts "[DRY RUN] Nothing will be moved. Set APPLY=true to move.\n\n" unless s3_migration_flag('APPLY')
      s3_migration_run_quarantine('Quarantine', :quarantine)
    end

    desc 'Undo a migration from the manifest (restores the disk copy and id). Dry run unless APPLY=true.'
    task rollback_s3_migration: :environment do
      s3_migration_require_s3!
      puts "[DRY RUN] Nothing will change. Set APPLY=true to roll back.\n\n" unless s3_migration_flag('APPLY')
      s3_migration_run_quarantine('Rolling back', :rollback)
    end

    desc 'Permanently delete quarantined files older than MIN_AGE_DAYS (default 14). Dry run unless APPLY=true.'
    task purge_quarantine: :environment do
      apply = s3_migration_flag('APPLY')
      puts "[DRY RUN] Nothing will be deleted. Set APPLY=true to delete.\n\n" unless apply
      purged, kept = Hyrax::S3Migration::Quarantine.purge(apply:, min_age: ENV.fetch('MIN_AGE_DAYS', '14').to_f.days)
      puts "#{apply ? 'Deleted' : 'Would delete'}: #{purged}  Too recent: #{kept}"
    end
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/MethodLength, Metrics/AbcSize
