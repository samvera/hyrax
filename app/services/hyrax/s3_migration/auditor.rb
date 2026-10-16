# frozen_string_literal: true

module Hyrax
  module S3Migration
    # Read-only check of one original file already in S3: the object must be readable, match the
    # recorded size, and match the stored checksum when one is present.
    class Auditor
      Result = Struct.new(:status, :problems, keyword_init: true)

      def initialize(original:, storage: Valkyrie::StorageAdapter)
        @original = original
        @storage = storage
      end

      # @return [Result] status is :ok, :problem or :not_in_s3
      def call
        return Result.new(status: :not_in_s3, problems: []) unless original.file_identifier.to_s.start_with?('shrine://')

        s3_file = storage.find_by(id: original.file_identifier)
        problems = size_problems(s3_file) + checksum_problems(s3_file)
        Result.new(status: problems.empty? ? :ok : :problem, problems:)
      end

      private

      attr_reader :original, :storage

      def size_problems(s3_file)
        recorded = original.recorded_size.first
        return [] unless recorded && s3_file.size.to_i != recorded.to_i

        ["size #{s3_file.size} != recorded #{recorded}"]
      end

      def checksum_problems(s3_file)
        stored = StoredChecksum.for(original)
        return [] unless stored

        actual = s3_file.checksum(digests: [stored.digest_class.new]).first
        actual == stored.digest ? [] : ["#{stored.algorithm} #{actual} != stored #{stored.digest}"]
      end
    end
  end
end
