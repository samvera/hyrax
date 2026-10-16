# frozen_string_literal: true

module Hyrax
  module S3Migration
    # The checksum Hyrax recorded for a file at characterization (FileMetadata#checksum). FITS reports
    # a bare MD5 hex string; an explicit urn:<algorithm>: prefix is also understood. Anything else
    # (unknown prefix, wrong length) is treated as no checksum rather than as a mismatch.
    class StoredChecksum
      PATTERN = /\A(?:urn:(?<algorithm>md5|sha1|sha256):)?(?<digest>\h+)\z/i
      ALGORITHMS = { 'md5' => [Digest::MD5, 32], 'sha1' => [Digest::SHA1, 40], 'sha256' => [Digest::SHA256, 64] }.freeze

      attr_reader :algorithm, :digest

      # @return [StoredChecksum, nil] nil when there is no usable checksum
      def self.for(original)
        match = PATTERN.match(original.checksum.first.to_s.strip)
        return unless match

        algorithm = match[:algorithm]&.downcase || 'md5'
        digest = match[:digest].downcase
        new(algorithm, digest) if digest.length == ALGORITHMS.fetch(algorithm).last
      end

      def initialize(algorithm, digest)
        @algorithm = algorithm
        @digest = digest
      end

      def digest_class
        ALGORITHMS.fetch(algorithm).first
      end

      def to_s
        "#{algorithm}:#{digest}"
      end
    end
  end
end
