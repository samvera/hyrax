# frozen_string_literal: true
module Hyrax
  ##
  # Store a file uploaded by a user.
  #
  # Eventually these files get attached to {FileSet}s and pushed into Fedora.
  #
  # Staged content is written to one of two storage backends, selected by
  # {Hyrax::Configuration#uploaded_file_storage_backend}: CarrierWave on the
  # local file system (the historical default) or Active Storage, where the
  # configured Active Storage service determines whether bytes land on local
  # disk, S3, etc. Reads through the storage-neutral API below dispatch on
  # what a record actually carries, so records created under either backend
  # remain readable after the configuration changes.
  class UploadedFile < ActiveRecord::Base
    self.table_name = 'uploaded_files'
    mount_uploader :file, UploadedFileUploader
    alias uploader file
    has_one_attached :file_attachment if respond_to?(:has_one_attached)
    has_many :job_io_wrappers,
             inverse_of: 'uploaded_file',
             class_name: 'JobIoWrapper',
             dependent: :destroy
    belongs_to :user, class_name: '::User'

    validate :virus_scan

    ##
    # Associate a {FileSet} with this uploaded file.
    #
    # @param [Hyrax::Resource, ActiveFedora::Base] file_set
    # @return [void]
    def add_file_set!(file_set)
      uri = case file_set
            when ActiveFedora::Base
              file_set.uri
            when Hyrax::Resource
              file_set.id
            end
      update!(file_set_uri: uri)
    end

    ##
    # Store content, routing it to the backend configured in
    # {Hyrax::Configuration#uploaded_file_storage_backend}.
    #
    # @param [IO, ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile] io
    # @param [String, nil] filename used when +io+ carries no filename of its
    #   own (plain +File+/+Tempfile+ objects under Active Storage)
    # @return [void]
    def store_file(io, filename: nil)
      if Hyrax.config.active_storage_uploads?
        file_attachment.attach(active_storage_attachable(io, filename))
      else
        # the CarrierWave mount handles ActionDispatch/Rack uploads and IOs
        self.file = io
      end
    end

    ##
    # @!group Storage-neutral file API
    #
    # The methods in this group are the storage-backend-neutral interface for
    # reading staged upload content and metadata. Hyrax internals outside the
    # ActiveFedora-specific code paths should prefer these over the
    # CarrierWave-specific {#uploader} interface, so the storage backing
    # {UploadedFile} can change without touching every consumer.

    ##
    # @return [String, nil] filename of the staged file; nil when no file
    #   content has been stored yet. Under Active Storage a filename recorded
    #   before content arrives (chunked uploads) is returned until then.
    def filename
      return file_attachment.filename.to_s if active_storage_backed?
      uploader.file&.filename || self[:file].presence
    end

    ##
    # @return [String, nil] MIME type of the staged file
    def content_type
      return file_attachment.content_type if active_storage_backed?
      uploader.file&.content_type if stored?
    end

    ##
    # @return [Integer, nil] size of the staged file in bytes
    def byte_size
      return file_attachment.byte_size if active_storage_backed?
      uploader.file&.size if stored?
    end

    ##
    # @return [Boolean] whether file content has been stored for this record
    def stored?
      active_storage_backed? || uploader.file.present?
    end

    ##
    # Yields a rewound, binary mode IO for the staged content. The IO responds
    # to +#path+ with a local filesystem path, as expected by Valkyrie storage
    # adapters that move files by path. The IO is closed when the block
    # returns.
    #
    # @yieldparam [IO] io readable IO positioned at the start of the file
    # @return [Object] the return value of the block
    # @see #stored? callers should ensure content is stored first
    def with_io(&block)
      raise ArgumentError, "expected a block" unless block_given?
      with_local_path { |path| File.open(path, 'rb', &block) }
    end

    ##
    # Yields a local filesystem path for the staged content.
    #
    # @note the path may be a temporary materialization depending on the
    #   storage backend; consumers must not assume it remains valid after the
    #   block returns.
    #
    # @yieldparam [String] path
    # @return [Object] the return value of the block
    # @see #stored? callers should ensure content is stored first
    def with_local_path
      raise ArgumentError, "expected a block" unless block_given?
      return file_attachment.blob.open { |tempfile| yield tempfile.path } if
        active_storage_backed?
      yield uploader.path
    end
    # @!endgroup

    ##
    # @return [Boolean] whether this record's content lives in Active Storage
    def active_storage_backed?
      respond_to?(:file_attachment) && file_attachment.attached?
    end

    ##
    # Under the Active Storage backend, route content assignment (including
    # the mass-assignment entry points used by the uploads controller and
    # legacy callers) to the attachment. A bare String records the intended
    # filename ahead of content, which the chunked upload protocol sends
    # before any bytes.
    def file=(new_file)
      return super unless Hyrax.config.active_storage_uploads?

      case new_file
      when String
        self[:file] = new_file
      when nil
        nil
      else
        store_file(new_file)
      end
    end

    private

    def active_storage_attachable(io, filename)
      return io if native_attachable?(io)

      name = filename ||
             (io.respond_to?(:original_filename) && io.original_filename) ||
             (io.respond_to?(:path) && io.path && File.basename(io.path)) ||
             self[:file].presence
      { io: io, filename: name }
    end

    # things Active Storage understands without an { io:, filename: } wrapper
    def native_attachable?(io)
      io.is_a?(::ActiveStorage::Blob) ||
        io.is_a?(ActionDispatch::Http::UploadedFile) ||
        (defined?(Rack::Test::UploadedFile) && io.is_a?(Rack::Test::UploadedFile))
    end

    def virus_scan
      path = path_for_virus_scan
      errors.add(:file, I18n.t('hyrax.virus_scanner.virus_detected', filename: path)) if
        path && Hyrax::VirusScanner.infected?(path)
    end

    # For CarrierWave the stored/cached file is scanned on every save (its
    # historical behavior). For Active Storage only newly attached content is
    # scanned, from the local source it is being attached from; already
    # uploaded blobs are immutable and were scanned when they arrived.
    def path_for_virus_scan
      return file.path unless Hyrax.config.active_storage_uploads?

      attachable = attachment_changes['file_attachment']&.attachable
      case attachable
      when Hash
        io = attachable[:io]
        io.respond_to?(:path) ? io.path : nil
      when nil
        nil
      else
        attachable.respond_to?(:path) ? attachable.path : nil
      end
    end
  end
end
