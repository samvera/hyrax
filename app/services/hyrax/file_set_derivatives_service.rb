module Hyrax
  # Responsible for creating and cleaning up the derivatives of a file_set
  class FileSetDerivativesService
    attr_reader :file_set
    delegate :uri, :mime_type, to: :file_set

    # @param file_set [Hyrax::FileSet] At least for this class, it must have #uri and #mime_type
    def initialize(file_set)
      @file_set = file_set
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
      when *file_set.class.pdf_mime_types             then create_pdf_derivatives(filename)
      when *file_set.class.office_document_mime_types then create_office_document_derivatives(filename)
      when *file_set.class.audio_mime_types           then create_audio_derivatives(filename)
      when *file_set.class.video_mime_types           then create_video_derivatives(filename)
      when *file_set.class.image_mime_types           then create_image_derivatives(filename)
      end
    end

    # The destination_name parameter has to match up with the file parameter
    # passed to the DownloadsController
    def derivative_url(destination_name)
      path = derivative_path_factory.derivative_path_for_reference(file_set, destination_name)
      URI("file://#{path}").to_s
    end

    private

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
        extract_full_text(filename, uri)
      end

      def create_office_document_derivatives(filename)
        Hydra::Derivatives::DocumentDerivatives.create(filename,
                                                       outputs: [{
                                                         label: :thumbnail, format: 'jpg',
                                                         size: '200x150>',
                                                         url: derivative_url('thumbnail'),
                                                         layer: 0
                                                       }])
        extract_full_text(filename, uri)
      end

      def create_audio_derivatives(filename)
        Hydra::Derivatives::AudioDerivatives.create(filename,
                                                    outputs: [{ label: 'mp3', format: 'mp3', url: derivative_url('mp3') },
                                                              { label: 'ogg', format: 'ogg', url: derivative_url('ogg') }])
      end

      def create_video_derivatives(filename)
        Hydra::Derivatives::VideoDerivatives.create(filename,
                                                    outputs: [{ label: :thumbnail, format: 'jpg', url: derivative_url('thumbnail') },
                                                              { label: 'webm', format: 'webm', url: derivative_url('webm') },
                                                              { label: 'mp4', format: 'mp4', url: derivative_url('mp4') }])
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
