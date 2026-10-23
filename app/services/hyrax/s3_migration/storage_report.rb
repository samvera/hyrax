# frozen_string_literal: true

module Hyrax
  module S3Migration
    # Tallies the files by use (original, thumbnail, ...) and storage scheme.
    class StorageReport
      # @param progress [Hyrax::S3Migration::Progress, nil] ticked once per file set
      # @return [Hash{Array<String>=>Array<Integer>}] { [use, scheme] => [file count, bytes] }
      def self.call(progress: nil)
        totals = Hash.new { |hash, key| hash[key] = [0, 0] }
        Hyrax::S3Migration.each_file_set do |file_set|
          progress&.tick
          files = files_for(file_set)
          totals[['(file record missing)', '-']][0] += 1 unless files
          files&.each do |file|
            key = [use_for(file), file.file_identifier.to_s[/\A[a-z]+(?=:)/].to_s]
            totals[key][0] += 1
            totals[key][1] += file.recorded_size.first.to_i
          end
        end
        totals
      end

      def self.files_for(file_set)
        Hyrax.custom_queries.find_files(file_set:)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end

      def self.use_for(file)
        Array(file.pcdm_use).map { |uri| uri.to_s.split('#').last }.join(',')
      end
    end
  end
end
