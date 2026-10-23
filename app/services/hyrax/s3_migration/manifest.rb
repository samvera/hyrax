# frozen_string_literal: true

module Hyrax
  module S3Migration
    # One JSON object per migrated file set under PREFIX in the repository bucket, written through
    # the S3 storage adapter, so parallel jobs never share a buffer and no separate S3 configuration
    # is needed. Entries are kept per Hyrax::S3Migration.scope when one is set.
    class Manifest
      PREFIX = '_migration-manifests'

      def initialize(storage: nil, scope: Hyrax::S3Migration.scope)
        @shrine = (storage || Valkyrie::StorageAdapter.find(:repository_s3)).shrine
        @scope = scope
      end

      def write(entry)
        shrine.upload(StringIO.new(entry.to_json), key_for(entry.fetch(:file_set_id)))
      end

      def read(file_set_id)
        parse(shrine.open(key_for(file_set_id)))
      rescue Shrine::FileNotFound
        nil
      end

      def each_entry
        return enum_for(:each_entry) unless block_given?

        shrine.bucket.objects(prefix: "#{[shrine.prefix, PREFIX, scope].compact.join('/')}/").each do |object|
          yield parse(object.get.body)
        end
      end

      private

      attr_reader :shrine, :scope

      def key_for(file_set_id)
        "#{[PREFIX, scope].compact.join('/')}/#{file_set_id}.json"
      end

      def parse(io)
        JSON.parse(io.read, symbolize_names: true)
      end
    end
  end
end
