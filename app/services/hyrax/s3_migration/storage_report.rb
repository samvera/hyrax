# frozen_string_literal: true

module Hyrax
  module S3Migration
    # Tallies the files by use (original, thumbnail, ...) and storage scheme.
    class StorageReport
      # @return [Hash{Array<String>=>Array<Integer>}] { [use, scheme] => [file count, bytes] }
      def self.call
        totals = Hash.new { |hash, key| hash[key] = [0, 0] }
        Hyrax::S3Migration.each_file_set do |file_set|
          Hyrax.custom_queries.find_files(file_set:).each do |file|
            key = [use_for(file), file.file_identifier.to_s[/\A[a-z]+(?=:)/].to_s]
            totals[key][0] += 1
            totals[key][1] += file.recorded_size.first.to_i
          end
        end
        totals
      end

      def self.use_for(file)
        Array(file.pcdm_use).map { |uri| uri.to_s.split('#').last }.join(',')
      end
    end
  end
end
