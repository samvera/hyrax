# frozen_string_literal: true

module Hyrax
  class MultiChecksum < Valkyrie::Resource
    attribute :sha256, Valkyrie::Types::SingleValuedString
    attribute :md5, Valkyrie::Types::SingleValuedString
    attribute :sha1, Valkyrie::Types::SingleValuedString

    def self.for(file_object)
      digests = file_object.checksum(digests: [Digest::MD5.new, Digest::SHA256.new, Digest::SHA1.new])
      MultiChecksum.new(
        md5: digests.shift,
        sha256: digests.shift,
        sha1: digests.shift
      )
    end
  end
end
