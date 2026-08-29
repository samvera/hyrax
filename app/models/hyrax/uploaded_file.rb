# frozen_string_literal: true
module Hyrax
  ##
  # Store a file uploaded by a user.
  #
  # Eventually these files get attached to {FileSet}s and pushed into Fedora.
  class UploadedFile < ActiveRecord::Base
    self.table_name = 'uploaded_files'
    mount_uploader :file, UploadedFileUploader
    alias uploader file
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
    # @!group Storage-neutral file API
    #
    # The methods in this group are the storage-backend-neutral interface for
    # reading staged upload content and metadata. Hyrax internals outside the
    # ActiveFedora-specific code paths should prefer these over the
    # CarrierWave-specific {#uploader} interface, so the storage backing
    # {UploadedFile} can change without touching every consumer.

    ##
    # @return [String, nil] filename of the staged file; nil when no file
    #   content has been stored yet
    def filename
      uploader.file&.filename
    end

    ##
    # @return [String, nil] MIME type of the staged file
    def content_type
      uploader.file&.content_type
    end

    ##
    # @return [Integer, nil] size of the staged file in bytes
    def byte_size
      uploader.file&.size
    end

    ##
    # @return [Boolean] whether file content has been stored for this record
    def stored?
      uploader.file.present?
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
      yield uploader.path
    end
    # @!endgroup

    private

    def virus_scan
      errors.add(:file, I18n.t('hyrax.virus_scanner.virus_detected', filename: file.path)) if
        file.path && Hyrax::VirusScanner.infected?(file.path)
    end
  end
end
