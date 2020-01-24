# frozen_string_literal: true

module Hyrax
  ##
  # Characterizes an ActiveFedora based FileSet
  class FileSetCharacterizer
    ##
    # @!attribute [rw] source
    #   @return [#characterize]
    attr_accessor :source

    ##
    # @param source the object to characterize
    def initialize(source:)
      @source = source
    end

    ##
    # @return [void]
    #
    # @raise [RuntimeError] if FileSet is missing the characterization_proxy
    def characterize
      Hydra::Works::CharacterizationService.run(characterization_proxy, filepath)
      Rails.logger.debug "Ran characterization on #{characterization_proxy.id} (#{characterization_proxy.mime_type})"
      characterization_proxy.alpha_channels = channels(filepath) if source.image? && Hyrax.config.iiif_image_server?
      characterization_proxy.save!
      source.update_index
      CreateDerivativesJob.perform_later(source, source.original_file.id, filepath)
    end

    private

      def characterization_proxy
        raise "#{source.class.characterization_proxy} was not found for FileSet #{source.id}" unless source.characterization_proxy?
        source.characterization_proxy
      end

      def filepath
        Hyrax::WorkingDirectory.find_or_retrieve(source.original_file.id, source.id)
      end

      def channels(path)
        ch = MiniMagick::Tool::Identify.new do |cmd|
          cmd.format '%[channels]'
          cmd << path
        end
        [ch]
      end
  end
end
