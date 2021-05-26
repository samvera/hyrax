# frozen_string_literal: true

module Hyrax
  ##
  # Resolves file sets to a mime type. Provides a series of utility methods for
  # figuring out what a file set is all about.
  class FileSetTypeService
    DEFAULT_AUDIO_TYPES = ['audio/mp3', 'audio/mpeg', 'audio/wav',
                           'audio/x-wave', 'audio/x-wav', 'audio/ogg'].freeze

    DEFAULT_IMAGE_TYPES = ["image/png", "image/jpeg", "image/jpg", "image/jp2",
                           "image/bmp", "image/gif", "image/tiff"].freeze

    DEFAULT_OFFICE_TYPES =
      ["text/rtf", "application/msword",
       "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
       "application/vnd.oasis.opendocument.text", "application/vnd.ms-excel",
       "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
       "application/vnd.ms-powerpoint",
       "application/vnd.openxmlformats-officedocument.presentationml.presentation"]
      .freeze

    DEFAULT_PDF_TYPES = ["application/pdf"].freeze

    DEFAULT_VIDEO_TYPES = ["video/mpeg", "video/mp4", "video/webm",
                           "video/x-msvideo", "video/avi", "video/quicktime",
                           "application/mxf"].freeze

    ##
    # @!attribute [r] file_set
    #   @return [Hyrax::FileSet]
    attr_reader :file_set

    ##
    # @todo make `file_set_characterization_proxy` (or something better?)
    #   application-level configuration.
    #
    # @param [Hyrax::FileSet] file_set
    # @param [Symbol] characterization_proxy defaults to the setting provided by
    #   the application's ActiveFedora `FileSet` class.
    def initialize(file_set:, characterization_proxy: ::FileSet.characterization_proxy, query_service: Hyrax.custom_queries)
      @file_set = file_set
      @proxy_use = Hyrax::FileMetadata::Use.uri_for(use: characterization_proxy)
      @queries = query_service
    end

    ##
    # @param [Hyrax::FileSet] file_set
    #
    # @return [#audio?, #image?, #office_document?, #pdf?, #video?]
    def self.for(file_set:, characterization_proxy: ::FileSet.characterization_proxy, **opts)
      case file_set
      when ActiveFedora::Base, HydraEditor::Form
        CatalogController.new.fetch(file_set.id).last
      when SolrDocument
        file_set
      else
        new(file_set: file_set, characterization_proxy: characterization_proxy, **opts)
      end
    end

    def metadata
      @metadata ||= @queries.find_many_file_metadata_by_use(resource: file_set, use: @proxy_use).first
    end

    ##
    # @return [String]
    def mime_type
      metadata&.mime_type || Hyrax::FileMetadata::GENERIC_MIME_TYPE
    end

    ##
    # @return [Boolean]
    def audio?
      audio_types.include?(mime_type)
    end

    ##
    # @return [Boolean]
    def image?
      image_types.include?(mime_type)
    end

    ##
    # @return [Boolean]
    def office_document?
      office_types.include?(mime_type)
    end

    ##
    # @return [Boolean]
    def pdf?
      pdf_types.include?(mime_type)
    end

    ##
    # @return [Boolean]
    def video?
      video_types.include?(mime_type)
    end

    private

    def audio_types
      return ::FileSet.audio_mime_types if defined?(::FileSet)
      DEFAULT_AUDIO_TYPES
    end

    def image_types
      return ::FileSet.image_mime_types if defined?(::FileSet)
      DEFAULT_IMAGE_TYPES
    end

    def office_types
      return ::FileSet.office_document_mime_types if defined?(::FileSet)
      DEFAULT_OFFICE_TYPES
    end

    def pdf_types
      return ::FileSet.pdf_mime_types if defined?(::FileSet)
      DEFAULT_PDF_TYPES
    end

    def video_types
      return ::FileSet.video_mime_types if defined?(::FileSet)
      DEFAULT_VIDEO_TYPES
    end
  end
end
