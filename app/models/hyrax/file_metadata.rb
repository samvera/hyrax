# frozen_string_literal: true

module Hyrax
  ##
  # Casts a resource to an associated FileMetadata
  #
  # @param [Valkyrie::StorageAdapter::File] file
  #
  # @return [Hyrax::FileMetadata]
  # @raise [ArgumentError]
  def self.FileMetadata(file)
    raise(ArgumentError, "Expected a Valkyrie::StorageAdapter::File; got #{file.class}: #{file}") if
      file.is_a?(Valkyrie::Resource)

    Hyrax.custom_queries.find_file_metadata_by(id: file.id)
  rescue Hyrax::ObjectNotFoundError, Ldp::BadRequest, Valkyrie::Persistence::ObjectNotFoundError
    Hyrax.logger.debug('Could not find an existing metadata node for file ' \
                       "with id #{file.id}. Initializing a new one")

    FileMetadata.new(file_identifier: file.id,
                     original_filename: File.basename(file.disk_path))
  end

  class FileMetadata < Valkyrie::Resource
    # Include mime-types for Hydra Derivatives mime-type checking. We may want
    # to move this logic someday.
    include Hydra::Works::MimeTypes

    GENERIC_MIME_TYPE = 'application/octet-stream'

    ##
    # Constants for PCDM Use URIs; use these constants in place of hard-coded
    # URIs in the `::Valkyrie::Vocab::PCDMUse` vocabulary.
    module Use
      EXTRACTED_TEXT = ::Valkyrie::Vocab::PCDMUse.ExtractedText
      INTERMEDIATE_FILE = ::Valkyrie::Vocab::PCDMUse.IntermediateFile
      ORIGINAL_FILE = ::Valkyrie::Vocab::PCDMUse.OriginalFile
      PRESERVATION_FILE = ::Valkyrie::Vocab::PCDMUse.PreservationFile
      SERVICE_FILE = ::Valkyrie::Vocab::PCDMUse.ServiceFile
      THUMBNAIL_IMAGE = ::Valkyrie::Vocab::PCDMUse.ThumbnailImage
      TRANSCRIPT = ::Valkyrie::Vocab::PCDMUse.Transcript

      THUMBNAIL = ::Valkyrie::Vocab::PCDMUse.ThumbnailImage # for compatibility with earlier versions of Hyrax; prefer +THUMBNAIL_IMAGE+

      # @return [Array<RDF::URI>] list of all uses
      def use_list
        [ORIGINAL_FILE,
         THUMBNAIL_IMAGE,
         EXTRACTED_TEXT,
         INTERMEDIATE_FILE,
         PRESERVATION_FILE,
         SERVICE_FILE,
         TRANSCRIPT]
      end
      module_function :use_list

      ##
      # @param use [RDF::URI, Symbol]
      #
      # @return [RDF::URI]
      # @raise [ArgumentError] if no use is known for the argument
      def uri_for(use:) # rubocop:disable Metrics/MethodLength
        case use
        when RDF::URI
          use
        when :extracted_file
          EXTRACTED_TEXT
        when :intermediate_file
          INTERMEDIATE_FILE
        when :original_file
          ORIGINAL_FILE
        when :preservation_file
          PRESERVATION_FILE
        when :service_file
          SERVICE_FILE
        when :thumbnail_file
          THUMBNAIL_IMAGE
        when :transcript_file
          TRANSCRIPT
        else
          raise ArgumentError, "No PCDM use is recognized for #{use}"
        end
      end
      module_function :uri_for
    end

    attribute :file_identifier, ::Valkyrie::Types::ID # id of the file stored by the storage adapter
    attribute :alternate_ids, Valkyrie::Types::Set.of(Valkyrie::Types::ID) # id of the file, populated for queryability
    attribute :file_set_id, ::Valkyrie::Types::ID # id of parent file set resource

    # all remaining attributes are on AF::File metadata_node unless otherwise noted
    attribute :label, ::Valkyrie::Types::Set
    attribute :original_filename, ::Valkyrie::Types::String
    attribute :mime_type, ::Valkyrie::Types::String.default(GENERIC_MIME_TYPE)
    attribute :pcdm_use, ::Valkyrie::Types::Set.default([Use::ORIGINAL_FILE].freeze) # Use += to add pcdm_uses, not <<

    # attributes set by fits
    attribute :format_label, ::Valkyrie::Types::Set
    attribute :recorded_size, ::Valkyrie::Types::Set
    attribute :well_formed, ::Valkyrie::Types::Set
    attribute :valid, ::Valkyrie::Types::Set
    attribute :date_created, ::Valkyrie::Types::Set
    attribute :fits_version, ::Valkyrie::Types::Set
    attribute :exif_version, ::Valkyrie::Types::Set
    attribute :checksum, ::Valkyrie::Types::Set

    # shared attributes across multiple file types
    attribute :frame_rate, ::Valkyrie::Types::Set # audio, video
    attribute :bit_rate, ::Valkyrie::Types::Set # audio, video
    attribute :duration, ::Valkyrie::Types::Set # audio, video
    attribute :sample_rate, ::Valkyrie::Types::Set # audio, video

    attribute :height, ::Valkyrie::Types::Set # image, video
    attribute :width, ::Valkyrie::Types::Set # image, video

    # attributes set by fits for audio files
    attribute :bit_depth, ::Valkyrie::Types::Set
    attribute :channels, ::Valkyrie::Types::Set
    attribute :data_format, ::Valkyrie::Types::Set
    attribute :offset, ::Valkyrie::Types::Set

    # attributes set by fits for documents
    attribute :file_title, ::Valkyrie::Types::Set
    attribute :creator, ::Valkyrie::Types::Set
    attribute :page_count, ::Valkyrie::Types::Set
    attribute :language, ::Valkyrie::Types::Set
    attribute :word_count, ::Valkyrie::Types::Set
    attribute :character_count, ::Valkyrie::Types::Set
    attribute :line_count, ::Valkyrie::Types::Set
    attribute :character_set, ::Valkyrie::Types::Set
    attribute :markup_basis, ::Valkyrie::Types::Set
    attribute :markup_language, ::Valkyrie::Types::Set
    attribute :paragraph_count, ::Valkyrie::Types::Set
    attribute :table_count, ::Valkyrie::Types::Set
    attribute :graphics_count, ::Valkyrie::Types::Set

    # attributes set by fits for images
    attribute :byte_order, ::Valkyrie::Types::Set
    attribute :compression, ::Valkyrie::Types::Set
    attribute :color_space, ::Valkyrie::Types::Set
    attribute :profile_name, ::Valkyrie::Types::Set
    attribute :profile_version, ::Valkyrie::Types::Set
    attribute :orientation, ::Valkyrie::Types::Set
    attribute :color_map, ::Valkyrie::Types::Set
    attribute :image_producer, ::Valkyrie::Types::Set
    attribute :capture_device, ::Valkyrie::Types::Set
    attribute :scanning_software, ::Valkyrie::Types::Set
    attribute :gps_timestamp, ::Valkyrie::Types::Set
    attribute :latitude, ::Valkyrie::Types::Set
    attribute :longitude, ::Valkyrie::Types::Set

    # attributes set by fits for video
    attribute :aspect_ratio, ::Valkyrie::Types::Set

    class << self
      ##
      # @return [String]
      def to_rdf_representation
        name
      end
    end

    ##
    # @return [Boolean]
    def original_file?
      pcdm_use.include?(Use::ORIGINAL_FILE)
    end

    ##
    # @return [Boolean]
    def thumbnail_file?
      pcdm_use.include?(Use::THUMBNAIL_IMAGE)
    end

    ##
    # @return [Boolean]
    def extracted_file?
      pcdm_use.include?(Use::EXTRACTED_TEXT)
    end

    ##
    # Filters out uses not recognized by Hyrax (e.g. http://fedora.info/definitions/v4/repository#Binary)
    # @return [Array]
    def filtered_pcdm_use
      pcdm_use.select { |use| Use.use_list.include?(use) }
    end

    ##
    # @return [String]
    def to_rdf_representation
      self.class.to_rdf_representation
    end

    def title
      label
    end

    def download_id
      id
    end

    def valid?
      file.valid?(size: recorded_size.first, digests: { sha256: checksum&.first&.sha256 })
    end

    ##
    # @deprecated get content from #file instead
    #
    # @return [#to_s]
    def content
      Deprecation.warn('This convienince method has been deprecated. ' \
                       'Retrieve the file from the storage adapter instead.')
      file.read
    rescue Valkyrie::StorageAdapter::FileNotFound
      ''
    end

    ##
    # @return [Valkyrie::StorageAdapter::File]
    #
    # @raise [Valkyrie::StorageAdapter::AdapterNotFoundError] if no adapter
    #   could be found matching the file_identifier's scheme
    # @raise [Valkyrie::StorageAdapter::FileNotFound] when the file can't
    #   be found in the registered adapter
    def file
      Valkyrie::StorageAdapter
        .adapter_for(id: file_identifier)
        .find_by(id: file_identifier)
    end
  end
end
