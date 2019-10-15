# frozen_string_literal: true

module Hyrax
  class FileMetadata < Valkyrie::Resource
    GENERIC_MIME_TYPE = 'application/octet-stream'

    ##
    # Constants for PCDM Use URIs; use these constants in place of hard-coded
    # URIs in the `::Valkyrie::Vocab::PCDMUse` vocabulary.
    module Use
      ORIGINAL_FILE = ::Valkyrie::Vocab::PCDMUse.OriginalFile
      EXTRACTED_TEXT = ::Valkyrie::Vocab::PCDMUse.ExtractedText
      THUMBNAIL = ::Valkyrie::Vocab::PCDMUse.ThumbnailImage

      ##
      # @param use [RDF::URI, Symbol]
      #
      # @return [RDF::URI]
      # @raise [ArgumentError] if no use is known for the argument
      def uri_for(use:)
        case use
        when RDF::URI
          use
        when :original_file
          ORIGINAL_FILE
        when :extracted_file
          EXTRACTED_TEXT
        when :thumbnail_file
          THUMBNAIL
        else
          raise ArgumentError, "No PCDM use is recognized for #{use}"
        end
      end
      module_function :uri_for
    end

    attribute :file_identifiers, ::Valkyrie::Types::Set # id of the file stored by the storage adapter
    attribute :alternate_ids, Valkyrie::Types::Set.of(Valkyrie::Types::ID) # id of the Hydra::PCDM::File which holds metadata and the file in ActiveFedora
    attribute :file_set_id, ::Valkyrie::Types::ID # id of parent file set resource

    # all remaining attributes are on AF::File metadata_node unless otherwise noted
    attribute :label, ::Valkyrie::Types::Set
    attribute :original_filename, ::Valkyrie::Types::Set
    attribute :mime_type, ::Valkyrie::Types::String.default(GENERIC_MIME_TYPE)
    attribute :type, ::Valkyrie::Types::Set.default([Use::ORIGINAL_FILE].freeze)
    attribute :content, ::Valkyrie::Types::Set

    # attributes set by fits
    attribute :format_label, ::Valkyrie::Types::Set
    attribute :size, ::Valkyrie::Types::Set
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

    # @param [ActionDispatch::Http::UploadedFile] file
    def self.for(file:)
      new(label: file.original_filename,
          original_filename: file.original_filename,
          mime_type: file.content_type)
    end

    ##
    # @return [Boolean]
    def original_file?
      type.include?(Use::ORIGINAL_FILE)
    end

    ##
    # @return [Boolean]
    def thumbnail_file?
      type.include?(Use::THUMBNAIL)
    end

    ##
    # @return [Boolean]
    def extracted_file?
      type.include?(Use::EXTRACTED_TEXT)
    end

    def title
      label
    end

    def download_id
      id
    end

    def valid?
      file.valid?(size: size.first, digests: { sha256: checksum&.first&.sha256 })
    end

    def file
      Hyrax.storage_adapter.find_by(id: file_identifiers.first)
    end
  end
end
