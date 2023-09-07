# frozen_string_literal: true
module Hyrax
  # Responsible for creating and cleaning up the derivatives of a file_set
  class FileSetDerivativesService
    attr_reader :file_set
    delegate :mime_type, to: :file_set

    # @param file_set [Hyrax::FileSet, Hyrax::FileMetadata] At least for this class, it must have #uri and #mime_type
    def initialize(file_set)
      @file_set = file_set
    end

    def uri
      # If given a FileMetadata object, use its parent ID.
      if file_set.respond_to?(:file_set_id)
        file_set.file_set_id.to_s
      else
        file_set.uri
      end
    end

    def cleanup_derivatives
      derivative_path_factory.derivatives_for_reference(file_set).each do |path|
        FileUtils.rm_f(path)
      end
    end

    def valid?
      supported_mime_types.include?(mime_type)
    end

    def create_derivatives(filename)
      case mime_type
      when *Hyrax.config.derivative_mime_type_mappings[:pdf]    then create_pdf_derivatives(filename)
      when *Hyrax.config.derivative_mime_type_mappings[:office] then create_office_document_derivatives(filename)
      when *Hyrax.config.derivative_mime_type_mappings[:audio]  then create_audio_derivatives(filename)
      when *Hyrax.config.derivative_mime_type_mappings[:video]  then create_video_derivatives(filename)
      when *Hyrax.config.derivative_mime_type_mappings[:image] then create_image_derivatives(filename)
      end
    end

    # The destination_name parameter has to match up with the file parameter
    # passed to the DownloadsController
    def derivative_url(destination_name)
      path = derivative_path_factory.derivative_path_for_reference(derivative_url_target, destination_name)
      URI("file://#{path}").to_s
    end

    private

    # If given a FileMetadata object pass the file_set_id for derivative URL
    # creation.
    def derivative_url_target
      if file_set.try(:file_set_id)
        file_set.file_set_id.to_s
      else
        file_set
      end
    end

    def supported_mime_types
      file_set.class.pdf_mime_types +
        file_set.class.office_document_mime_types +
        file_set.class.audio_mime_types +
        file_set.class.video_mime_types +
        file_set.class.image_mime_types
    end

    def create_pdf_derivatives(filename)
      Hydra::Derivatives::PdfDerivatives.create(filename,
                                                outputs: [{
                                                  label: :thumbnail,
                                                  format: 'jpg',
                                                  size: '338x493',
                                                  url: derivative_url('thumbnail'),
                                                  layer: 0
                                                }])
      extract_full_text(filename, derivative_url('extracted_text'))
    end

    def create_office_document_derivatives(filename)
      Hydra::Derivatives::DocumentDerivatives.create(filename,
                                                     outputs: [{
                                                       label: :thumbnail, format: 'jpg',
                                                       size: '200x150>',
                                                       url: derivative_url('thumbnail'),
                                                       layer: 0
                                                     }])
      extract_full_text(filename, derivative_url('extracted_text'))
    end

    def create_audio_derivatives(filename)
      Hydra::Derivatives::AudioDerivatives.create(filename,
                                                  outputs: [{ label: 'mp3', format: 'mp3', url: derivative_url('mp3'), mime_type: 'audio/mpeg', container: 'service_file' },
                                                            { label: 'ogg', format: 'ogg', url: derivative_url('ogg'), mime_type: 'audio/ogg', container: 'service_file' }])
    end

    def create_video_derivatives(filename)
      Hydra::Derivatives::VideoDerivatives.create(filename,
                                                  outputs: [{ label: :thumbnail, format: 'jpg', url: derivative_url('thumbnail'), mime_type: 'image/jpeg' },
                                                            { label: 'webm', format: 'webm', url: derivative_url('webm'), mime_type: 'video/webm', container: 'service_file' },
                                                            { label: 'mp4', format: 'mp4', url: derivative_url('mp4'), mime_type: 'video/mp4', container: 'service_file' }])
    end

    def create_image_derivatives(filename)
      # We're asking for layer 0, becauase otherwise pyramidal tiffs flatten all the layers together into the thumbnail
      Hydra::Derivatives::ImageDerivatives.create(filename,
                                                  outputs: [{ label: :thumbnail,
                                                              format: 'jpg',
                                                              size: '200x150>',
                                                              url: derivative_url('thumbnail'),
                                                              layer: 0 }])
    end

    def derivative_path_factory
      Hyrax::DerivativePath
    end

    # Calls the Hydra::Derivates::FulltextExtraction unless the extract_full_text
    # configuration option is set to false
    # @param [String] filename of the object to be used for full text extraction
    # @param [String] uri to the file set (deligated to file_set)
    def extract_full_text(filename, uri)
      return unless Hyrax.config.extract_full_text?

      Hydra::Derivatives::FullTextExtract.create(filename,
                                                 outputs: [{ url: uri, container: "extracted_text" }])
    end
  end
end
