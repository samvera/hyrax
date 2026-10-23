# frozen_string_literal: true

# Thin wrappers: the work lives in Hyrax::S3Migration::* and the MigrateFilesToS3Job /
# MigrateFileSetToS3Job jobs. See documentation/migrating-files-to-s3.md.
# rubocop:disable Metrics/BlockLength, Metrics/MethodLength, Metrics/AbcSize
namespace :hyrax do
  namespace :migrate do
    desc 'Read-only report of file storage by file use and scheme (disk, shrine, ...).'
    task report_file_storage: :environment do
      puts "use | scheme | files | GB"
      Hyrax::S3Migration::StorageReport.call(progress: Hyrax::S3Migration::Progress.new).sort.each do |(use, scheme), (count, bytes)|
        puts "#{use} | #{scheme} | #{count} | #{(bytes / 1e9).round(2)}"
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength, Metrics/MethodLength, Metrics/AbcSize
