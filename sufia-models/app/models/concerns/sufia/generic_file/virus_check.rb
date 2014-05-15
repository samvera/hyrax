module Sufia
  module GenericFile
    module VirusCheck
      extend ActiveSupport::Concern

      included do
        validate :detect_viruses
      end

      # Default behavior is to raise a validation error and halt the save if a virus is found
      def detect_viruses
        return unless content.changed?
        path = if content.content.respond_to?(:path)
                 content.content.path
               else
                 Tempfile.open('') do |t|
                   t.binmode
                   t.write(content.content)
                   t.close
                   t.path
                 end
               end
        Sufia::GenericFile::Actor.virus_check(path)
        true
      rescue Sufia::VirusFoundError => virus
        logger.warn(virus.message)
        errors.add(:base, virus.message)
        false
      end
    end
  end
end
