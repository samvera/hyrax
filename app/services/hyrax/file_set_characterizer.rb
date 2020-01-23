# frozen_string_literal: true

module Hyrax
  ##
  # Propogates visibility from a given Work to its FileSets
  class FileSetCharacterizer 
    ##
    # @!attribute [rw] source
    #   @return [#visibility]
    attr_accessor :source

    ##
    # @param source [#visibility] the object to propogate visibility from
    def initialize(source:)
      self.source = source
    end

    ##
    # @return [void]
    #
    # @raise [RuntimeError] if visibility propogation fails
    def characterize
      Hydra::Works::CharacterizationService.run(source.characterization_proxy, filepath)
      Rails.logger.debug "Ran characterization on #{source.characterization_proxy.id} (#{source.characterization_proxy.mime_type})"
      source.characterization_proxy.alpha_channels = channels(filepath) if source.image? && Hyrax.config.iiif_image_server?
      source.characterization_proxy.save!
      source.update_index
      source.parent&.in_collections&.each(&:update_index)
      CreateDerivativesJob.perform_later(source, source.original_file.id, filepath)
    end

    private

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
