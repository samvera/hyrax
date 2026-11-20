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
      create_derivatives_for(:pdf, filename, Hydra::Derivatives::PdfDerivatives)
    end

    def create_office_document_derivatives(filename)
      create_derivatives_for(:office, filename, Hydra::Derivatives::DocumentDerivatives)
    end

    def create_audio_derivatives(filename)
      create_derivatives_for(:audio, filename, Hydra::Derivatives::AudioDerivatives)
    end

    def create_video_derivatives(filename)
      create_derivatives_for(:video, filename, Hydra::Derivatives::VideoDerivatives)
    end

    def create_image_derivatives(filename)
      create_derivatives_for(:image, filename, Hydra::Derivatives::ImageDerivatives)
    end

    # Routes +extracted_text+ outputs to full text extraction; the rest to +processor+.
    def create_derivatives_for(type, filename, processor)
      text_outputs, processor_outputs = derivative_outputs(type).partition { |output| output[:container] == 'extracted_text' }
      processor.create(filename, outputs: processor_outputs) if processor_outputs.any?
      extract_full_text(filename, text_outputs) if text_outputs.any?
    end

    # Resolves configured specs for +type+: callable values are invoked with the
    # file set, and +:url+ destination names become real derivative URLs.
    def derivative_outputs(type)
      Hyrax.config.derivative_options.fetch(type).map do |output|
        resolved = output.transform_values { |value| value.respond_to?(:call) ? value.call(file_set) : value }
        resolved.merge(url: derivative_url(resolved[:url]))
      end
    end

    def derivative_path_factory
      Hyrax::DerivativePath
    end

    # Calls the Hydra::Derivates::FulltextExtraction unless the extract_full_text
    # configuration option is set to false
    # @param [String] filename of the object to be used for full text extraction
    # @param [Array<Hash>] outputs the resolved extracted_text output specs
    def extract_full_text(filename, outputs)
      return unless Hyrax.config.extract_full_text?

      Hydra::Derivatives::FullTextExtract.create(filename, outputs: outputs)
    end
  end
end
