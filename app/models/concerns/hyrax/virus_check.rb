# frozen_string_literal: true
module Hyrax
  module VirusCheck
    extend ActiveSupport::Concern

    included do
      validate :must_not_detect_viruses

      def viruses?
        return false unless original_file&.new_record? # We have a new file to check
        VirusCheckerService.file_has_virus?(original_file)
      end

      def must_not_detect_viruses
        return true unless viruses?
        errors.add(:base, "Failed to verify uploaded file is not a virus")
        false
      end
    end
  end
end
