module CurationConcerns
  module GenericFile
    module VirusCheck
      extend ActiveSupport::Concern

      included do
        validate :detect_viruses
      end

      # Default behavior is to raise a validation error and halt the save if a virus is found
      def detect_viruses
        return unless original_file && original_file.new_record?
        CurationConcerns::VirusDetectionService.run(original_file)
        true
      rescue CurationConcerns::VirusFoundError => virus
        logger.warn(virus.message)
        errors.add(:base, virus.message)
        false
      end

    end
  end
end
