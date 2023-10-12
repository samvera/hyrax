# frozen_string_literal: true
module Hyrax
  # Riiif file resolver for valkyrie resources
  class RiiifFileResolver
    include ActiveSupport::Benchmarkable

    # @param [String] id from iiif manifest
    # @return [Riiif::File]
    def find(id)
      path = nil
      file_locks[id].with_write_lock do
        path = build_path(id)
        path = build_path(id, force: true) unless File.exist?(path) # Ensures the file is locally available
      end
      RiiifFile.new(path, id: id)
    end

    # tracks individual file locks
    # @see RiiifFile
    # @return [Concurrent::Map<Concurrent::ReadWriteLock>]
    def file_locks
      @file_locks ||= Concurrent::Map.new do |k, v|
        k.compute_if_absent(v) { Concurrent::ReadWriteLock.new }
      end
    end

    private

    def build_path(id, force: false)
      Riiif::Image.cache.fetch("riiif:" + Digest::MD5.hexdigest("path:#{id}"),
                               expires_in: Riiif::Image.expires_in,
                               force: force) do
        load_file(id)
      end
    end

    def load_file(id)
      benchmark "RiiifFileResolver loaded #{id}", level: :debug do
        fs_id = id.sub(/\A([^\/]*)\/.*/, '\1')
        file_set = Hyrax.query_service.find_by(id: fs_id)
        file_metadata = Hyrax.custom_queries.find_original_file(file_set: file_set)
        file_metadata.file.disk_path.to_s # Stores a local copy in tmpdir
      end
    end

    def logger
      Hyrax.logger
    end
  end
end
