# frozen_string_literal: true

module Hyrax
  module Storage
    ##
    # A Valkyrie StorageAdapter backed by Rails Active Storage blobs.
    #
    # Files are stored as +ActiveStorage::Blob+ records (no
    # +ActiveStorage::Attachment+ join rows), so the configured Active
    # Storage service — +config/storage.yml+ and
    # +config.active_storage.service+, or the +service_name:+ given to this
    # adapter — decides where the bytes live. Switching a repository between
    # local disk and S3 (or any other Active Storage service) is a Rails
    # storage configuration change; nothing in Hyrax needs to know.
    #
    # Versioning follows the same scheme as
    # +Valkyrie::Storage::VersionedDisk+, encoded in blob keys instead of
    # file paths: each version is stored under
    # +<key_prefix><resource_id>/v-<timestamp>-<filename>+ and file
    # identifiers circulate in the "current reference" form
    # +active-storage://<key_prefix><resource_id>/v-current-<filename>+,
    # which always resolves to the newest version. That keeps
    # {Hyrax::FileMetadata#file_identifier} stable as new versions arrive,
    # exactly as with VersionedDisk.
    #
    # @example registering an adapter
    #   Valkyrie::StorageAdapter.register(
    #     Hyrax::Storage::ActiveStorage.new, :active_storage
    #   )
    #
    # @example a second instance on a dedicated service for derivatives
    #   Valkyrie::StorageAdapter.register(
    #     Hyrax::Storage::ActiveStorage.new(key_prefix: 'hyrax/derivatives/',
    #                                       service_name: :derivatives),
    #     :active_storage_derivatives
    #   )
    #
    # @note resource ids may not contain "/" (true of Hyrax's Valkyrie
    #   adapters, which use UUID-style ids); filenames may.
    class ActiveStorage
      PROTOCOL = 'active-storage://'
      CURRENT = 'current'

      ##
      # @return [String] key namespace for blobs written by this adapter
      attr_reader :key_prefix

      ##
      # @return [Symbol, nil] Active Storage service blobs are written to;
      #   nil uses the application default service
      attr_reader :service_name

      # @param key_prefix [String]
      # @param service_name [Symbol, String, nil]
      def initialize(key_prefix: 'hyrax/files/', service_name: nil)
        @key_prefix = "#{key_prefix.to_s.delete_prefix('/').chomp('/')}/"
        @service_name = service_name&.to_s
      end

      # @param file [IO]
      # @param original_filename [String]
      # @param resource [Valkyrie::Resource, nil]
      # @return [Valkyrie::StorageAdapter::StreamFile]
      def upload(file:, original_filename:, resource: nil, paused: false, **_extra_arguments)
        resource_segment = resource&.id.to_s.presence || SecureRandom.uuid
        key = version_key(resource_segment, current_timestamp, original_filename)
        # If we've gone faster than milliseconds, pause a millisecond and
        # re-call, mirroring Valkyrie::Storage::VersionedDisk.
        return sleep(0.001) && upload(file: file, original_filename: original_filename, resource: resource, paused: true) if
          !paused && ::ActiveStorage::Blob.exists?(key: key)

        blob = create_blob(file, key, original_filename)
        build_file(VersionKey.new(key), blob)
      end

      # @param id [Valkyrie::ID] a stored file id, in current-reference or
      #   concrete version form
      # @param file [IO]
      # @return [Valkyrie::StorageAdapter::StreamFile] the new version
      def upload_version(id:, file:, paused: false)
        parsed = parse(id)
        key = version_key(parsed.resource_segment, current_timestamp, parsed.filename)
        return sleep(0.001) && upload_version(id: id, file: file, paused: true) if
          !paused && ::ActiveStorage::Blob.exists?(key: key)

        blob = create_blob(file, key, parsed.filename)
        build_file(VersionKey.new(key), blob)
      end

      # @param id [Valkyrie::ID]
      # @return [Boolean]
      def handles?(id:)
        id.to_s.start_with?("#{PROTOCOL}#{key_prefix}")
      end

      # @param feature [Symbol]
      # @return [Boolean]
      def supports?(feature)
        feature == :versions || feature == :version_deletion
      end

      # @return [String]
      def protocol
        PROTOCOL
      end

      # @param id [Valkyrie::ID]
      # @return [Valkyrie::StorageAdapter::StreamFile]
      # @raise [Valkyrie::StorageAdapter::FileNotFound]
      def find_by(id:)
        parsed = parse(id)
        version = parsed.reference? ? newest_version(parsed) : parsed
        raise Valkyrie::StorageAdapter::FileNotFound if version.nil? || version.deletion_marker?

        blob = blob_scope.find_by(key: version.key)
        raise Valkyrie::StorageAdapter::FileNotFound if blob.nil?
        build_file(version, blob)
      end

      # @param id [Valkyrie::ID]
      # @return [Array<Valkyrie::StorageAdapter::StreamFile>] newest first
      def find_versions(id:)
        parsed = parse(id)
        version_blobs(parsed).reject { |version, _blob| version.deletion_marker? }
                             .map { |version, blob| build_file(version, blob) }
      end

      # Deleting the current version deletes all versions (matching
      # VersionedDisk); deleting a superseded version deletes only it.
      #
      # @param id [Valkyrie::ID]
      # @return [void]
      def delete(id:)
        parsed = parse(id)

        if parsed.reference? || parsed == newest_version(parsed)
          version_blobs(parsed).each { |_version, blob| blob.purge }
        else
          blob_scope.find_by(key: parsed.key)&.purge
        end
      end

      private

      def current_timestamp
        Time.now.strftime("%s%L")
      end

      def version_key(resource_segment, timestamp, filename)
        "#{key_prefix}#{resource_segment}/v-#{timestamp}-#{filename}"
      end

      def create_blob(file, key, filename)
        file.rewind if file.respond_to?(:rewind)
        ::ActiveStorage::Blob.create_and_upload!(
          key: key,
          io: file,
          filename: File.basename(filename.to_s),
          identify: false,
          service_name: service_name
        )
      end

      def blob_scope
        scope = ::ActiveStorage::Blob.all
        scope = scope.where(service_name: service_name) if service_name
        scope
      end

      def parse(id)
        VersionKey.from_id(id: id, adapter: self)
      end

      # @return [Array<(VersionKey, ActiveStorage::Blob)>] all versions of
      #   the parsed file, newest first
      def version_blobs(parsed)
        pattern = "#{ActiveRecord::Base.sanitize_sql_like("#{key_prefix}#{parsed.resource_segment}/v-")}%"
        blob_scope.where(::ActiveStorage::Blob.arel_table[:key].matches(pattern, nil, true))
                  .order(key: :desc)
                  .filter_map do |blob|
          version = VersionKey.new(blob.key)
          [version, blob] if version.filename == parsed.filename
        end
      end

      # @return [VersionKey, nil] the newest version of the parsed file
      def newest_version(parsed)
        version_blobs(parsed).first&.first
      end

      def build_file(version, blob)
        Valkyrie::StorageAdapter::StreamFile.new(
          id: Valkyrie::ID.new("#{PROTOCOL}#{version.current_reference_key}"),
          io: BlobIO.new(blob),
          version_id: Valkyrie::ID.new("#{PROTOCOL}#{version.key}")
        )
      end

      ##
      # Parses this adapter's blob keys:
      # +<key_prefix><resource_segment>/v-<timestamp>-<filename>+, where
      # +<timestamp>+ may be the reference marker +current+ and +<filename>+
      # may itself contain slashes or a +deletionmarker-+ prefix.
      class VersionKey
        VERSION_PATTERN = /\Av-(?<version>current|\d+)-(?<marker>deletionmarker-)?(?<filename>.*)\z/m

        ##
        # @param id [Valkyrie::ID]
        # @param adapter [Hyrax::Storage::ActiveStorage]
        # @return [VersionKey]
        # @raise [Valkyrie::StorageAdapter::FileNotFound] for ids this
        #   adapter could not have written
        def self.from_id(id:, adapter:)
          key = id.to_s.delete_prefix(PROTOCOL)
          raise Valkyrie::StorageAdapter::FileNotFound unless key.start_with?(adapter.key_prefix)
          new(key, prefix: adapter.key_prefix)
        end

        attr_reader :key, :prefix

        def initialize(key, prefix: nil)
          @key = key
          @prefix = prefix || key[%r{\A(.*/)[^/]+/v-}m, 1]
          raise Valkyrie::StorageAdapter::FileNotFound unless parts
        end

        def resource_segment
          local = key.delete_prefix(prefix.to_s)
          local.split('/', 2).first
        end

        def version
          parts[:version]
        end

        def filename
          parts[:filename]
        end

        def deletion_marker?
          !parts[:marker].nil?
        end

        def reference?
          version == CURRENT
        end

        def current_reference_key
          "#{versionless_prefix}v-#{CURRENT}-#{filename}"
        end

        def ==(other)
          other.is_a?(self.class) && other.key == key
        end

        private

        # everything through "<resource_segment>/"
        def versionless_prefix
          local = key.delete_prefix(prefix.to_s)
          "#{prefix}#{local.split('/', 2).first}/"
        end

        def parts
          return @parts if defined?(@parts)
          local = key.delete_prefix(prefix.to_s)
          _segment, version_part = local.split('/', 2)
          @parts = version_part&.match(VERSION_PATTERN)
        end
      end

      ##
      # A lazy IO for a blob: nothing downloads until the content is read.
      # Responds to the subset of IO used by +Valkyrie::StorageAdapter::File+
      # (+read+, +rewind+, +close+, +size+, +path+, +each+), materializing the
      # blob to a tempfile on first content access so +#path+/+#disk_path+
      # consumers (characterization, derivatives, downloads) keep working.
      class BlobIO
        ##
        # @return [ActiveStorage::Blob]
        attr_reader :blob

        def initialize(blob)
          @blob = blob
        end

        def size
          blob.byte_size
        end

        def read(*args)
          tempfile.read(*args)
        end

        def rewind
          tempfile.rewind
        end

        def each(...)
          tempfile.each(...)
        end

        def path
          tempfile.path
        end

        def close
          return unless @tempfile
          @tempfile.close
          @tempfile.unlink if @tempfile.respond_to?(:unlink)
          @tempfile = nil
        end

        private

        def tempfile
          @tempfile ||= Tempfile.new(['hyrax-active-storage', File.extname(blob.filename.to_s)], binmode: true).tap do |file|
            blob.download { |chunk| file.write(chunk) }
            file.flush
            file.rewind
          end
        end
      end
    end
  end
end
